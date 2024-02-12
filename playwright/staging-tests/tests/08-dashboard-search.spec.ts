import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json',
  viewport: {
    height: 720,
    width: 1280
  }
});

test('dashboard search', async ({ page }) => {
  await page.goto(url);

  await expect(page.locator('#banner')).toBeVisible();

  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');

  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();

  await page.getByRole('link', { name: 'Dashboard' }).click();

  await expect(page.getByPlaceholder('Search for names..')).toBeEmpty();

  await page.getByPlaceholder('Search for names..').click();

  await page.getByPlaceholder('Search for names..').fill('anchor');

  await page.getByPlaceholder('Search for names..').press('Enter');

  await expect(page.getByPlaceholder('Search for names..')).toHaveValue('anchor');

  await expect(page.locator('#searchDiv div').filter({ hasText: 'Anchor Point (APT)' })).toBeVisible();

  await page.getByPlaceholder('Search for names..').click();

  await page.getByPlaceholder('Search for names..').fill('bishop');

  await expect(page.getByPlaceholder('Search for names..')).toHaveValue('bishop');

  await page.getByPlaceholder('Search for names..').press('Enter');

  await expect(page.locator('#searchDiv div').filter({ hasText: 'Bishop\'s Falls (BSF)' })).toBeVisible();

  await page.getByPlaceholder('Search for names..').click();

  await page.getByPlaceholder('Search for names..').fill('');

  await page.getByPlaceholder('Search for names..').click();

  await page.getByPlaceholder('Search for names..').fill('dover');

  await expect(page.getByPlaceholder('Search for names..')).toHaveValue('dover');

  await expect(page.locator('#searchDiv div').filter({ hasText: 'Dover (DOV)' })).toBeVisible();

  await page.getByPlaceholder('Search for names..').click();

  await page.getByPlaceholder('Search for names..').fill('kaslo');

  await expect(page.getByPlaceholder('Search for names..')).toHaveValue('kaslo');

  await expect(page.locator('#searchDiv div').filter({ hasText: 'Kaslo (KAS)' })).toBeVisible();

  await page.getByPlaceholder('Search for names..').click();

  await page.getByPlaceholder('Search for names..').fill('wellington');

  await expect(page.getByPlaceholder('Search for names..')).toHaveValue('wellington');

  await expect(page.locator('#searchDiv div').filter({ hasText: 'Wellington (WLT)' })).toBeVisible();

  await page.getByPlaceholder('Search for names..').click();

  await page.getByPlaceholder('Search for names..').fill('victoria');

  await expect(page.getByPlaceholder('Search for names..')).toHaveValue('victoria');

  await expect(page.locator('#searchDiv div').filter({ hasText: 'Victoria (VIC)' })).toBeVisible();

  await expect(page.locator('#searchDiv div').filter({ hasText: 'Victoria County (VTC)' })).toBeVisible();

  await page.getByPlaceholder('Search for names..').click();
  
  await page.getByPlaceholder('Search for names..').fill('');
});