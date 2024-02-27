import { test as setup, expect } from '@playwright/test';

let url = '/';

const useremail = 'admin@example.com';
const password = 'admin';

setup('authentication', async ({ page }) => {
  await page.goto(url);

  const initialURL = page.url();

  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');

  await expect(page.locator('#profile')).toContainText('An affordable, user friendly asset management platform for small communities. MyCivitas is an all-inclusive, easy to use platform that lets you record and manage your assets in one powerful information system.');

  await expect(page.locator('#banner')).toBeVisible();

  await expect(page.getByRole('button', { name: 'Have an account? — SIGN IN' })).toBeVisible();

  await page.getByRole('button', { name: 'Have an account? — SIGN IN' }).click();

  await page.getByPlaceholder('Email address').click();

  await page.getByPlaceholder('Email address').fill(useremail);

  await page.getByPlaceholder('Password').click();

  await page.getByPlaceholder('Password').fill(password);

  await page.getByRole('button', { name: 'Sign In' }).click();

  await page.waitForURL('**/community-map');

  const finalURL = page.url();

  await expect(finalURL).not.toBe(initialURL);

  await expect(page.locator('#profile-navbar')).toBeVisible();

});