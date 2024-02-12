import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json'
});

test('test', async ({ page }) => {
  await page.goto(url);

  await expect(page.locator('#banner')).toBeVisible();

  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');

  await expect(page.locator('#profile')).toContainText('An affordable, user friendly asset management platform for small communities. MyCivitas is an all-inclusive, easy to use platform that lets you record and manage your assets in one powerful information system.');

  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();

  await page.getByRole('button', { name: 'Open Community Map' }).click();

  await page.waitForURL('**/community-map');

  await page.getByTitle('Assets').locator('i').first().click();

  await page.locator('#see-layer-list i').click();

  await page.locator('#risk_list div').filter({ hasText: 'Consequence of Failure' }).getByRole('radio').check();

  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(5000);

  await page.getByLabel('Map').click({
    position: {
      x: 719,
      y: 395
    }
  });

  await expect(page.getByText('Water Supply.Valve.61882')).toBeVisible();

  await expect(page.locator('#feature-61882')).toContainText('ID 61882');

  await expect(page.locator('#feature-61882')).toContainText('Newfoundland and Labrador');

  await expect(page.locator('#feature-61882')).toContainText('St. Anthony-Port aux Choix Region');

  await expect(page.getByText('Water Supply.Pipe.59766')).toBeVisible();

  await expect(page.locator('#feature-59766')).toContainText('ID 59766');

  await expect(page.locator('#feature-59766')).toContainText('Newfoundland and Labrador');
  
  await expect(page.locator('#feature-59766')).toContainText('St. Anthony-Port aux Choix Region');

  //await expect(page.getByText('Ticket (0)').first()).toBeVisible();

  //await page.getByText('Ticket (0)').first().click();

  await expect(page.getByRole('cell', { name: 'Newfoundland and Labrador' }).first()).toBeVisible();

  await expect(page.getByRole('cell', { name: 'Province' }).first()).toBeVisible();

  await expect(page.getByRole('cell', { name: 'Region', exact: true }).first()).toBeVisible();

  await expect(page.getByRole('cell', { name: 'St. Anthony-Port aux Choix' }).first()).toBeVisible();

  await page.getByText('Add asset for creating ticket Remove asset from creating ticket').first().click();

  await expect(page.locator('#feature-61882')).toContainText('Remove asset from creating ticket');

  await page.getByTitle('Create Ticket').locator('i').first().click();

  await expect(page.locator('#widget-create-ticket')).toContainText('Below is the asset(s) selected for the new ticket. Click here to show the asset(s) on the map.');

  await expect(page.locator('#feature-ticket-list').getByText('Water Supply.Valve.61882')).toBeVisible();

  //await expect(page.getByLabel('Type')).toBeEmpty();

  await page.getByLabel('Type').selectOption('2');

  await expect(page.getByLabel('Type')).toHaveValue('2');

  await page.getByLabel('Summary of issue or task').click();

  await page.getByLabel('Summary of issue or task').fill('Test playwright');

  await page.getByLabel('Description of issue or task').click();

  await page.getByLabel('Description of issue or task').fill('Test');

  await page.getByPlaceholder('Hours').click();

  await page.getByPlaceholder('Hours').fill('1');

  await page.getByLabel('Assign to\n                        \n                            (Optional)').selectOption('9');

  await expect(page.getByRole('button', { name: 'Create Ticket' })).toBeVisible();

  await page.getByRole('button', { name: 'Create Ticket' }).click();

  await expect(page.getByText('Test playwright')).toBeVisible();

  await expect(page.locator('div').filter({ hasText: /^New$/ })).toBeVisible();

  await expect(page.getByText('Corrective Maintenance')).toBeVisible();

  await expect(page.locator('#map')).toBeVisible();
});