import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json',
  viewport: {
    height: 720,
    width: 1280
  }
});

test('test for view table', async ({ page }) => {
  await page.goto(url);

  await expect(page.locator('#banner')).toBeVisible();

  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');

  await expect(page.locator('#profile')).toContainText('An affordable, user friendly asset management platform for small communities. MyCivitas is an all-inclusive, easy to use platform that lets you record and manage your assets in one powerful information system.');

  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'View Table' })).toBeVisible();

  await page.getByRole('link', { name: 'View Table' }).click();

  await page.waitForURL('**/community-map**');

  await page.waitForLoadState('load');

  await expect(page.getByText('Export search close Choose Column Filter Default Detailed Custom ZoomFeature')).toBeVisible({timeout: 30000});

  await expect(page.getByRole('heading')).toContainText('Export');

  await expect(page.getByRole('textbox', { name: 'Type in a name' })).toBeEmpty();

  await page.getByText('Choose Column Filter').click();

  await expect(page.locator('#column-filter')).toHaveValue('default');

  await expect(page.locator('#filteredhead')).toContainText('Zoom');

  await expect(page.locator('#filteredhead')).toContainText('Feature ID');

  await expect(page.locator('#filteredhead')).toContainText('Community');

  await expect(page.locator('#filteredhead')).toContainText('System');

  await expect(page.locator('#filteredhead')).toContainText('Sub Class');

  await expect(page.locator('#filteredhead')).toContainText('Asset Type');

  await expect(page.locator('#filteredhead')).toContainText('Quantity');

  await expect(page.locator('#filteredhead')).toContainText('Sub Class Unit Description');

  await expect(page.locator('#filteredhead')).toContainText('Renewal Cost');

  await expect(page.locator('#filteredhead')).toContainText('Lifespan');

  await expect(page.getByRole('row', { name: 'search 59592 Anchor Point' }).getByRole('button')).toBeVisible();

  await expect(page.locator('#table_show')).toContainText('59592');

  await expect(page.locator('#table_show')).toContainText('Anchor Point');

  await expect(page.locator('#table_show')).toContainText('Transportation');

  await expect(page.locator('#table_show')).toContainText('Road Overlay');

  await expect(page.locator('#table_show')).toContainText('Lane');

  await expect(page.locator('#table_show')).toContainText('934.8');

  await expect(page.locator('#table_show')).toContainText('Square meter');

  await expect(page.locator('#table_show')).toContainText('46740');

  await expect(page.locator('#table_show')).toContainText('20');

  await page.locator('th:nth-child(7) > .search-column').click();

  await page.locator('th:nth-child(7) > .search-column').fill('934.8');

  await expect(page.getByRole('cell', { name: '934.8' })).toBeVisible();

  await page.locator('th:nth-child(7) > .search-column').click();

  await page.locator('th:nth-child(7) > .search-column').fill('');

  await expect(page.getByRole('cell', { name: '1088.46' })).toBeVisible();

  await expect(page.getByRole('cell', { name: '972.54' })).toBeVisible();

  await expect(page.getByRole('cell', { name: '2 3 4 ... 28' })).toBeVisible();

  await expect(page.getByRole('button', { name: 'Export to CSV' })).toBeVisible();

  await expect(page.getByRole('button', { name: 'Close' })).toBeVisible();

  // download event
  const downloadPromise = page.waitForEvent('download');

  await page.getByRole('button', { name: 'Export to CSV' }).click();

  const download = await downloadPromise;

  await download.saveAs('tests/download/' + download.suggestedFilename());
  // file downloaded

  await expect(page.locator('#table_show')).toContainText('59592');

  await page.getByRole('row', { name: 'search 59592 Anchor Point' }).getByRole('button').click();

  await expect(page.locator('#feature-59592')).toContainText('Transportation Network.Road Overlay.59592');

  await expect(page.getByText('Assets', { exact: true })).toBeVisible();

  await expect(page.locator('#feature-59592')).toContainText('ID 59592');

  await page.getByLabel('Map').click({
    position: {
      x: 778,
      y: 318
    }
  });

  await expect(page.getByRole('table')).toContainText('934.80');
});