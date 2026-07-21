function normalizeTokenDocuments(documents) {
  const tokens = documents
    .map((document) => document.data().token || document.id)
    .filter((token) => typeof token === 'string' && token.length > 0);

  return [...new Set(tokens)];
}

function buildTestNotificationMessage(tokens) {
  return {
    tokens,
    notification: {
      title: 'テスト通知',
      body: "We's Volleyball Managerの通知設定は正常です。",
    },
    data: {
      type: 'test',
    },
    webpush: {
      notification: {
        title: 'テスト通知',
        body: "We's Volleyball Managerの通知設定は正常です。",
        icon: '/icons/Icon-192.png',
      },
      fcmOptions: {
        link: '/',
      },
    },
  };
}

module.exports = {
  buildTestNotificationMessage,
  normalizeTokenDocuments,
};
