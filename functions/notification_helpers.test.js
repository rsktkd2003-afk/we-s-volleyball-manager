const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildTestNotificationMessage,
  normalizeTokenDocuments,
} = require('./notification_helpers');

test('normalizeTokenDocuments removes empty and duplicate tokens', () => {
  const documents = [
    { id: 'fallback', data: () => ({ token: 'token-a' }) },
    { id: 'token-b', data: () => ({}) },
    { id: 'duplicate', data: () => ({ token: 'token-a' }) },
    { id: 'empty', data: () => ({ token: '' }) },
  ];

  assert.deepEqual(normalizeTokenDocuments(documents), [
    'token-a',
    'token-b',
    'empty',
  ]);
});

test('buildTestNotificationMessage targets only supplied tokens', () => {
  const message = buildTestNotificationMessage(['token-a', 'token-b']);

  assert.deepEqual(message.tokens, ['token-a', 'token-b']);
  assert.equal(message.data.type, 'test');
  assert.equal(message.notification.title, 'テスト通知');
});
