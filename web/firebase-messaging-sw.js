importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCK1p56VGv_e01txhKQH2Hby9G2RQe7lR4',
  authDomain: 'we-s-volleyball-manager.firebaseapp.com',
  projectId: 'we-s-volleyball-manager',
  storageBucket: 'we-s-volleyball-manager.firebasestorage.app',
  messagingSenderId: '131334385712',
  appId: '1:131334385712:web:ea30d265235aace0963df5',
  measurementId: 'G-WY3QSPKXHD',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || '通知';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(title, options);
});