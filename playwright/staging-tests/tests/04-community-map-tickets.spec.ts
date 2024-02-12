import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json'
});

test.describe('community-map-tickets', () => {
  test.beforeEach(async ({ page }) => {
    // Go to the starting url before each test.
    await page.goto(url);
  });

  test('test ticket', async ({ page }) => {

    await expect(page.locator('#banner')).toBeVisible();

    await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');

    await expect(page.locator('#profile')).toContainText('An affordable, user friendly asset management platform for small communities. MyCivitas is an all-inclusive, easy to use platform that lets you record and manage your assets in one powerful information system.');

    await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();

    await page.getByRole('button', { name: 'Open Community Map' }).click();

    await page.waitForURL('**/community-map');

    await expect(page.getByLabel('Map')).toBeVisible();

    await expect(page.locator('#community')).toBeVisible();

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(5000);

    await page.getByLabel('Map').click({
      position: {
        x: 378,
        y: 323
      }
    });

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

    await expect(page.getByText('When you are readyclick here')).toBeVisible();

    await page.getByTitle('Create Ticket').click();

    await expect(page.locator('#widget-create-ticket')).toContainText('Below is the asset(s) selected for the new ticket. Click here to show the asset(s) on the map.');

    await expect(page.locator('#feature-ticket-list').getByText('Water Supply.Pipe.59766')).toBeVisible();

    //await expect(page.getByLabel('Type')).toBeEmpty();

    await page.getByLabel('Type').selectOption('3');

    await expect(page.getByLabel('Type')).toHaveValue('3');

    await page.getByLabel('Summary of issue or task').click();

    await page.getByLabel('Summary of issue or task').fill('Ticket test');

    await page.getByLabel('Description of issue or task').click();

    await page.getByLabel('Description of issue or task').fill('Ticket test');

    await expect(page.getByLabel('Priority')).toHaveValue('3');

    await page.getByPlaceholder('Hours').click();

    await page.getByPlaceholder('Hours').fill('1');

    await page.getByLabel('Assign to\n                        \n                            (Optional)').selectOption('9');

    await expect(page.getByRole('button', { name: 'Create Ticket' })).toBeVisible();

    await page.getByRole('button', { name: 'Create Ticket' }).click();

    await page.waitForURL('**/work-order/tickets/**')

    await expect(page.getByText(' Ticket test').first()).toBeVisible();

    await expect(page.locator('div').filter({ hasText: /^New$/ })).toBeVisible();

    await expect(page.getByText('Public Tickets')).toBeVisible();

    await expect(page.locator('#map')).toBeVisible();

    //await expect(page.locator('#map div').filter({ hasText: 'Aimsoir feature code -' }).nth(3)).toBeVisible();

    //await page.getByRole('link', { name: '×' }).click();

    //await expect(page.locator('#comment-25 div').filter({ hasText: 'Ticket test' })).toBeVisible();

    await expect(page.getByText('Priority')).toBeVisible();

    await expect(page.getByText('Normal').first()).toBeVisible();

    await page.getByText('Start date').click();

    //await expect(page.getByText('Feb. 6, 2024, midnight (None)')).toBeVisible();

    await expect(page.getByRole('textbox', { name: 'Leave a comment' })).toBeEmpty();

    await expect(page.getByRole('button', { name: 'Save & Comment' })).toBeVisible();

    await expect(page.getByRole('button', { name: 'Edit' })).toBeVisible();

    await expect(page.getByRole('button', { name: 'Delete' })).toBeVisible();

    await page.getByText('Expected time to complete task').click();

    await expect(page.locator('#detail-form')).toContainText('01h:00m');

    await expect(page.getByText('Time spent (Optional) :')).toBeVisible();

    await page.getByRole('link', { name: 'Community Map' }).click();

    await page.waitForURL('**/community-map');

    await page.waitForLoadState('domcontentloaded');

    await expect(page.getByText('Tickets', { exact: true })).toBeVisible();

    await expect(page.getByRole('link', { name: 'Ticket test' })).toBeVisible();
  });

  test('delete ticket', async ({ page }) => {
    
    await page.getByRole('button', { name: 'Open Community Map' }).click();

    await page.waitForURL('**/community-map');

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(5000);

    await expect(page.getByRole('link', { name: 'Ticket test' })).toBeVisible();

    const page1Promise = page.waitForEvent('popup');
    await page.getByRole('link', { name: 'Ticket test' }).click();
    const page1 = await page1Promise;

    await expect(page1.getByText('Ticket test')).toBeVisible();

    await expect(page1.locator('#map')).toBeVisible();

    await expect(page1.getByText('Normal').first()).toBeVisible();

    page1.once('dialog', dialog => {
      console.log(`Dialog message: ${dialog.message()}`);
      dialog.accept();
    });

    await page1.getByRole('button', { name: 'Delete' }).click();

    await page1.getByRole('link', { name: 'Community Map' }).click();

    await page.waitForURL('**/community-map');
    await page.waitForTimeout(5000);

    //await expect(page.getByRole('link', { name: 'Ticket test' })).not.toBeVisible();
  });

});
