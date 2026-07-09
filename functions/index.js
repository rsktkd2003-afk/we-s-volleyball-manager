const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.notifyAnnouncementCreated = onDocumentCreated('announcements/{announcementId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;

  await sendNotificationToAllUsers({
    title: '新しいお知らせ',
    body: data.title ? `${data.title}` : '新しいお知らせが追加されました。',
    data: {
      type: 'announcement',
      announcementId: event.params.announcementId,
    },
  });
});

exports.notifyMatchPollCreated = onDocumentCreated('match_polls/{pollId}', async (event) => {
  const data = event.data?.data();
  if (!data || data.status !== 'open') return;

  await sendNotificationToAllUsers({
    title: '新しいアンケート',
    body: data.title ? `${data.title} のアンケートが作成されました。` : '試合候補日のアンケートが作成されました。',
    data: {
      type: 'match_poll',
      pollId: event.params.pollId,
    },
  });
});

exports.sendScheduleReminders = onSchedule(
  {
    schedule: 'every 5 minutes',
    timeZone: 'Asia/Tokyo',
  },
  async () => {
    const now = new Date();
    const oneHourStart = new Date(now.getTime() + 60 * 60 * 1000);
    const oneHourEnd = new Date(now.getTime() + 65 * 60 * 1000);

    await sendOneHourReminders(oneHourStart, oneHourEnd);

    const tokyoParts = getTokyoParts(now);
    if (tokyoParts.hour === 20 && tokyoParts.minute < 5) {
      await sendDayBeforeReminders(now);
    }
  }
);

async function sendOneHourReminders(start, end) {
  const snapshot = await db
    .collection('schedules')
    .where('start', '>=', admin.firestore.Timestamp.fromDate(start))
    .where('start', '<', admin.firestore.Timestamp.fromDate(end))
    .get();

  for (const doc of snapshot.docs) {
    const schedule = doc.data();
    if (schedule.notificationStatus?.oneHourBeforeSentAt) continue;

    const title = getScheduleNotificationTitle(schedule.title);
    const body = `${formatTokyoTime(schedule.start.toDate())} から${getScheduleTypeText(schedule.title)}があります。${formatLocation(schedule.location)}`;

    await sendNotificationToAllUsers({
      title,
      body,
      data: {
        type: 'schedule',
        scheduleId: doc.id,
        reminderType: 'oneHourBefore',
      },
    });

    await doc.ref.set({
      notificationStatus: {
        oneHourBeforeSentAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, { merge: true });
  }
}

async function sendDayBeforeReminders(now) {
  const tomorrowRange = getTomorrowTokyoRange(now);

  const snapshot = await db
    .collection('schedules')
    .where('start', '>=', admin.firestore.Timestamp.fromDate(tomorrowRange.start))
    .where('start', '<', admin.firestore.Timestamp.fromDate(tomorrowRange.end))
    .get();

  for (const doc of snapshot.docs) {
    const schedule = doc.data();
    if (schedule.notificationStatus?.dayBeforeSentAt) continue;

    const title = getScheduleNotificationTitle(schedule.title);
    const body = `明日 ${formatTokyoTime(schedule.start.toDate())} から${getScheduleTypeText(schedule.title)}があります。${formatLocation(schedule.location)}`;

    await sendNotificationToAllUsers({
      title,
      body,
      data: {
        type: 'schedule',
        scheduleId: doc.id,
        reminderType: 'dayBefore',
      },
    });

    await doc.ref.set({
      notificationStatus: {
        dayBeforeSentAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, { merge: true });
  }
}

async function sendNotificationToAllUsers({ title, body, data }) {
  const tokens = await getAllTokens();
  if (tokens.length === 0) return;

  const chunks = chunk(tokens, 500);

  for (const tokenChunk of chunks) {
    const response = await messaging.sendEachForMulticast({
      tokens: tokenChunk,
      notification: { title, body },
      data: stringifyData(data),
      webpush: {
        notification: {
          title,
          body,
          icon: '/icons/Icon-192.png',
        },
        fcmOptions: {
          link: '/',
        },
      },
    });

    await deleteInvalidTokens(tokenChunk, response.responses);
  }
}

async function getAllTokens() {
  const usersSnapshot = await db.collection('users').get();
  const tokens = [];

  for (const userDoc of usersSnapshot.docs) {
    const tokenSnapshot = await userDoc.ref.collection('fcmTokens').get();
    for (const tokenDoc of tokenSnapshot.docs) {
      const token = tokenDoc.data().token || tokenDoc.id;
      if (typeof token === 'string' && token.length > 0) {
        tokens.push(token);
      }
    }
  }

  return [...new Set(tokens)];
}

async function deleteInvalidTokens(tokens, responses) {
  const invalidTokens = [];

  responses.forEach((response, index) => {
    if (!response.success) {
      const code = response.error?.code;
      if (
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/registration-token-not-registered'
      ) {
        invalidTokens.push(tokens[index]);
      }
    }
  });

  for (const token of invalidTokens) {
    const usersSnapshot = await db.collection('users').get();
    for (const userDoc of usersSnapshot.docs) {
      const tokenRef = userDoc.ref.collection('fcmTokens').doc(token);
      const tokenDoc = await tokenRef.get();
      if (tokenDoc.exists) {
        await tokenRef.delete();
      }
    }
  }
}

function getScheduleNotificationTitle(scheduleTitle) {
  return scheduleTitle?.includes('試合') ? '試合のお知らせ' : '練習のお知らせ';
}

function getScheduleTypeText(scheduleTitle) {
  return scheduleTitle?.includes('試合') ? '試合' : '練習';
}

function formatLocation(location) {
  if (!location || String(location).trim().length === 0) return '';
  return `\n場所：${String(location).trim()}`;
}

function formatTokyoTime(date) {
  return new Intl.DateTimeFormat('ja-JP', {
    timeZone: 'Asia/Tokyo',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(date);
}

function getTokyoParts(date) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Tokyo',
    hour: 'numeric',
    minute: 'numeric',
    hour12: false,
  }).formatToParts(date);

  return {
    hour: Number(parts.find((part) => part.type === 'hour')?.value ?? 0),
    minute: Number(parts.find((part) => part.type === 'minute')?.value ?? 0),
  };
}

function getTomorrowTokyoRange(now) {
  const tokyoDate = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(now);

  const startTodayUtc = new Date(`${tokyoDate}T00:00:00+09:00`);
  const startTomorrow = new Date(startTodayUtc.getTime() + 24 * 60 * 60 * 1000);
  const endTomorrow = new Date(startTomorrow.getTime() + 24 * 60 * 60 * 1000);

  return { start: startTomorrow, end: endTomorrow };
}

function stringifyData(data) {
  const result = {};
  for (const [key, value] of Object.entries(data || {})) {
    result[key] = String(value);
  }
  return result;
}

function chunk(items, size) {
  const result = [];
  for (let i = 0; i < items.length; i += size) {
    result.push(items.slice(i, i + size));
  }
  return result;
}