import { test, expect } from '@playwright/test';

test.describe('Todo機能', () => {
  test.beforeEach(async ({ page }) => {
    // ログインしてからテストを実行
    await page.goto('/login');
    await page.waitForLoadState('networkidle');
    await page.waitForSelector('#email');

    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'password123');
    await page.click('button[type="submit"]');

    // ログイン後の処理を待機
    await page.waitForTimeout(10000);

    // ログイン成功後、Todoページにいることを確認
    await expect(page).toHaveURL('/');

    // Todoページの読み込みを待機
    await page.waitForTimeout(3000);
  });

  test('新しいTodoを追加できる', async ({ page }) => {
    // 既存のTodoの数を確認
    const initialTodoCount = await page.locator('.todo-item').count();

    // 新しいTodoのタイトルを入力
    await page.waitForSelector('input[placeholder*="新しいタスク"]');
    await page.fill('input[placeholder*="新しいタスク"]', '新しいタスク');

    // 追加ボタンをクリック
    await page.click('button[type="submit"]:has-text("追加")');

    // Todoがリストに追加されることを確認
    await page.waitForTimeout(2000);
    const newTodoCount = await page.locator('.todo-item').count();

    // 新しいTodoが追加されたことを確認
    expect(newTodoCount).toBe(initialTodoCount + 1);

    // 新しく追加されたTodoが存在することを確認
    await expect(page.locator('.todo-item:has-text("新しいタスク")')).toBeVisible();
  });

  test('Todoを完了状態にできる', async ({ page }) => {
    // 既存のTodoを完了状態にする
    await page.waitForSelector('.todo-checkbox');
    await page.locator('.todo-checkbox').first().click();

    // 完了状態になったことを確認
    await page.waitForTimeout(1000);
    await expect(page.locator('.todo-item.completed').first()).toBeVisible();
  });

  test('Todoを削除できる', async ({ page }) => {
    // 削除ボタンをクリック
    await page.waitForSelector('button:has-text("削除")');
    await page.locator('button:has-text("削除")').first().click();

    // 削除ボタンが存在することを確認
    await expect(page.locator('button:has-text("削除")').first()).toBeVisible();
  });

  test('複数のTodoを管理できる', async ({ page }) => {
    // 既存のTodoの数を確認
    const initialTodoCount = await page.locator('.todo-item').count();

    // 複数のTodoを追加
    await page.waitForSelector('input[placeholder*="新しいタスク"]');

    // 最初のTodoを追加
    await page.fill('input[placeholder*="新しいタスク"]', 'テストタスク1');
    await page.click('button[type="submit"]:has-text("追加")');
    await page.waitForTimeout(1000);

    // 2番目のTodoを追加
    await page.fill('input[placeholder*="新しいタスク"]', 'テストタスク2');
    await page.click('button[type="submit"]:has-text("追加")');
    await page.waitForTimeout(1000);

    // 3番目のTodoを追加
    await page.fill('input[placeholder*="新しいタスク"]', 'テストタスク3');
    await page.click('button[type="submit"]:has-text("追加")');
    await page.waitForTimeout(1000);

    // 3つのTodoが追加されたことを確認
    const finalTodoCount = await page.locator('.todo-item').count();
    expect(finalTodoCount).toBe(initialTodoCount + 3);

    // 新しく追加されたTodoが存在することを確認
    await expect(page.locator('.todo-item:has-text("テストタスク1")')).toBeVisible();
    await expect(page.locator('.todo-item:has-text("テストタスク2")')).toBeVisible();
    await expect(page.locator('.todo-item:has-text("テストタスク3")')).toBeVisible();

    // 特定のTodoを完了状態にする
    const newTodos = page.locator('.todo-item:has-text("テストタスク")');
    await newTodos.nth(1).locator('.todo-checkbox').click();

    // 完了状態のTodoが1つあることを確認
    await page.waitForTimeout(1000);
    await expect(page.locator('.todo-item.completed:has-text("テストタスク2")')).toBeVisible();
  });
});
