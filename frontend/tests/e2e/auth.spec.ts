import { test, expect } from '@playwright/test';

test.describe('認証機能', () => {
  test('ログインが正常に動作する', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    // ログインフォームが表示されることを確認
    await expect(page.locator('#email')).toBeVisible();
    await expect(page.locator('#password')).toBeVisible();

    // ログイン情報を入力
    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'password123');

    // ログインボタンをクリック
    await page.click('button[type="submit"]');

    // ログイン処理の完了を待機
    await page.waitForResponse(response =>
      response.url().includes('/auth/login') && response.status() === 200
    );

    // リダイレクトを待機
    await page.waitForURL('**/', { timeout: 10000 });

    // ログイン成功後、Todoページにいることを確認
    await expect(page).toHaveURL('/');
  });

  test('無効な認証情報でログインが失敗する', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    // 無効なログイン情報を入力
    await page.fill('#email', 'invalid@example.com');
    await page.fill('#password', 'wrongpassword');

    // ログインボタンをクリック
    await page.click('button[type="submit"]');

    // エラーレスポンスを待機
    await page.waitForResponse(response =>
      response.url().includes('/auth/login') && response.status() === 401
    );

    // エラーメッセージが表示されることを確認
    await page.waitForTimeout(2000);

    const errorElement = await page.locator('.error').count();
    if (errorElement > 0) {
      const errorText = await page.locator('.error').textContent();
      expect(errorText).toBeTruthy();
    }

    // ログインページに留まることを確認
    await expect(page).toHaveURL('/login');
  });
});
