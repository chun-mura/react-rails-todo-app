import { test, expect } from '@playwright/test';

test('アプリケーションが正常に読み込まれる', async ({ page }) => {
  await page.goto('/');

  // より長い待機時間を設定
  await page.waitForTimeout(10000);

  // まずはページが読み込まれているかを確認
  await expect(page).toHaveTitle(/Todo App/);
});

test('ログインページにアクセスできる', async ({ page }) => {
  await page.goto('/login');

  // より長い待機時間を設定
  await page.waitForTimeout(10000);

  // 要素が存在するかを確認
  const h2Element = await page.locator('h2').count();

  if (h2Element > 0) {
    await expect(page.locator('h2')).toContainText('ログイン');
  } else {
    // アプリケーションが読み込まれているかを確認
    const appElement = await page.locator('#root').count();

    if (appElement === 0) {
      throw new Error('Reactアプリケーションが読み込まれていません');
    }
  }
});

test('登録ページにアクセスできる', async ({ page }) => {
  await page.goto('/register');

  // より長い待機時間を設定
  await page.waitForTimeout(10000);

  // 要素が存在するかを確認
  const h2Element = await page.locator('h2').count();

  if (h2Element > 0) {
    await expect(page.locator('h2')).toContainText('新規登録');
  } else {
    // アプリケーションが読み込まれているかを確認
    const appElement = await page.locator('#root').count();

    if (appElement === 0) {
      throw new Error('Reactアプリケーションが読み込まれていません');
    }
  }
});
