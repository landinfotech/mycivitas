import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json',
  viewport: {
    height: 720,
    width: 1280
  }
});

test('work orders', async ({ page }) => {
  await page.goto(url);
  await expect(page.locator('#banner')).toBeVisible();
  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');
  await expect(page.locator('#profile')).toContainText('An affordable, user friendly asset management platform for small communities. MyCivitas is an all-inclusive, easy to use platform that lets you record and manage your assets in one powerful information system.');
  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Work Orders' })).toBeVisible();
  await page.getByRole('link', { name: 'Work Orders' }).click();

  await page.waitForURL('**/work-order/tickets/');

  await expect(page.getByRole('button', { name: 'Reports & Statistics' })).toBeVisible();
  await expect(page.getByRole('tab', { name: ' Table' })).toBeVisible();
  await expect(page.getByRole('tab', { name: ' Timeline' })).toBeVisible();
  await expect(page.getByRole('gridcell', { name: 'Test playwright' }).locator('div')).toBeVisible();
  await expect(page.locator('.even > td:nth-child(2)').first()).toBeVisible();
  await expect(page.getByRole('row', { name: '11. Test playwright' }).locator('div').nth(1)).toBeVisible();
  await expect(page.getByRole('row', { name: '11. Test playwright' }).locator('div').nth(2)).toBeVisible();
  await expect(page.getByRole('gridcell', { name: '1. TEST', exact: true })).toBeVisible();
  await expect(page.locator('td:nth-child(2)').first()).toBeVisible();
  await expect(page.getByRole('row', { name: '1. TEST Corrective' }).locator('div').nth(1)).toBeVisible();
  await expect(page.getByRole('row', { name: '1. TEST Corrective' }).locator('div').nth(2)).toBeVisible();
  await page.getByLabel('Search:').click();
  await page.getByLabel('Search:').fill('playwright');
  await expect(page.getByRole('gridcell', { name: 'Test playwright' }).locator('div')).toBeVisible();
  await expect(page.getByText('Showing 1 to 1 of 1 entries (')).toBeVisible();
  await expect(page.getByLabel('Search:')).toHaveValue('playwright');
  await page.getByLabel('Search:').click();
  
  await page.getByRole('tab', { name: ' Timeline' }).click();
  await expect(page.locator('#test-ticket-opened div').filter({ hasText: '7:59:55 AM December 14,' }).nth(1)).toBeVisible();
  await expect(page.locator('.tl-timenav-slider-background')).toBeVisible();
  await expect(page.locator('#test-ticket-opened-marker').getByRole('heading', { name: 'TEST - Ticket Opened' })).toBeVisible();
  await page.locator('.tl-slidenav-icon').first().click();
  await expect(page.locator('#test-ticket-opened-2 div').filter({ hasText: '2:18:46 PM January 9,' }).nth(1)).toBeVisible();
  //await expect(page.locator('#tl-gfkcnd')).toContainText('test - Ticket Opened');
  await expect(page.locator('#test-ticket-opened-3-marker').getByRole('heading', { name: 'test - Ticket Opened' })).toBeVisible();
  await expect(page.locator('#test-ticket-opened-4-marker div').filter({ hasText: 'test - Ticket Opened' }).nth(1)).toBeVisible();
  await page.locator('.tl-slidenav-icon').first().click();
  await expect(page.locator('#test-ticket-opened-3 div').filter({ hasText: '6:47:46 AM January 10,' }).nth(1)).toBeVisible();
  await expect(page.getByRole('tab', { name: ' Table' })).toBeVisible();
  
  await page.getByRole('button', { name: 'Reports & Statistics' }).click();
  await page.waitForURL('**/work-order/reports/');
  await expect(page.getByText('Reports & Statistics').first()).toBeVisible();
  await expect(page.locator('#content')).toContainText('Average number of days until ticket is closed (all tickets):');
  await expect(page.locator('#content')).toContainText('Average number of days until ticket is closed (tickets opened in last 60 days):');
  await expect(page.getByRole('cell', { name: 'Queue' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'New' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Corrective Maintenance' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Public Tickets' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Scheduled Work' })).toBeVisible();
  
  await page.getByText('Reports By User').click();
  await page.getByRole('link', { name: 'by Priority' }).first().click();
  await page.waitForURL('**/work-order/reports/userpriority/');
  await expect(page.getByRole('cell', { name: 'User' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Critical' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Normal' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Low', exact: true })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Very Low' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Unassigned' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '10' })).toBeVisible();
  await expect(page.getByText('Created with Raphaël 2.2.002.')).toBeVisible();
  
  await page.getByRole('link', { name: 'by Queue' }).click();
  await page.waitForURL('**/work-order/reports/userqueue/');
  await expect(page.getByRole('cell', { name: 'User' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Corrective Maintenance' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Public Tickets' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Scheduled Work' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Unassigned' })).toBeVisible();
  await expect(page.getByText('Created with Raphaël 2.2.002468Scheduled WorkPublic TicketsCorrective')).toBeVisible();
  
  await page.getByRole('link', { name: 'by Status' }).first().click();
  await page.waitForURL('**/work-order/reports/userstatus/');
  await expect(page.getByRole('cell', { name: 'User' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'New' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Open', exact: true })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Reopened' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Resolved' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Closed' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Duplicate' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Rejected' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Unassigned' })).toBeVisible();
  await expect(page.getByText('Created with Raphaël 2.2.002.')).toBeVisible();

  await page.getByRole('link', { name: 'by Month' }).first().click();
  await page.waitForURL('**/work-order/reports/usermonth/');
  await expect(page.getByRole('cell', { name: 'User' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-12' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-01' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-02' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-03' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Unassigned' })).toBeVisible();
  await expect(page.getByText('Created with Raphaël 2.2.000.')).toBeVisible();
  await expect(page.locator('circle:nth-child(28)')).toBeVisible();
  await page.locator('circle:nth-child(31)').click();
  await expect(page.locator('circle:nth-child(31)')).toBeVisible();
  
  await page.getByRole('link', { name: 'by Priority' }).nth(1).click();
  await page.waitForURL('**/work-order/reports/queuepriority/');
  await expect(page.getByRole('cell', { name: 'Queue' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Critical' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'High' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Normal' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Low', exact: true })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Very Low' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Corrective Maintenance' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Public Tickets' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Scheduled Work' })).toBeVisible();
  await expect(page.getByText('Created with Raphaël 2.2.0036912Very LowLowNormalHighCritical')).toBeVisible();
  
  await page.getByRole('link', { name: 'by Month' }).nth(1).click();
  await page.waitForURL('**/work-order/reports/queuemonth/');
  await expect(page.getByRole('cell', { name: 'Queue' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-12' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-01' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-02' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '-03' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Corrective Maintenance' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Public Tickets' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Scheduled Work' })).toBeVisible();
  await expect(page.getByText('Created with Raphaël 2.2.0024682024-032024-022024-012023-')).toBeVisible();
  await page.locator('circle:nth-child(29)').click();
});