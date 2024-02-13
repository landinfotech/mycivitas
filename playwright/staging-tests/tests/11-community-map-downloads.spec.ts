import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json',
  viewport: {
    height: 720,
    width: 1280
  }
});

test('test file downloads', async ({ page }) => {
  await page.goto(url);
  await expect(page.locator('#banner')).toBeVisible();
  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');
  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();
  await page.getByRole('link', { name: 'Community Map', exact: true }).click();
  await page.waitForURL('**/community-map');
  await page.getByTitle('Assets').locator('i').first().click();
  await page.getByText('See Layer List').click();
  await page.locator('#risk_list div').filter({ hasText: 'Consequence of Failure' }).getByRole('radio').check();
  await page.locator('#hide-layer-list i').click();
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
  await expect(page.locator('#features-detail').getByRole('button')).toBeVisible();
  await page.locator('#features-detail').getByRole('button').click();
  await expect(page.getByRole('heading', { name: 'Export' })).toBeVisible();
  await expect(page.locator('#modal_export')).toContainText('Please choose what data you would like to be exported');
  await expect(page.getByRole('button', { name: 'Export to CSV' })).toBeVisible();
  // dowanload event
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Export to CSV' }).click();
  const download = await downloadPromise;
  await download.saveAs('tests/download/' + download.suggestedFilename());
  // downloaded

  await page.locator('#modal_export').getByText('Close').click();
  await page.getByTitle('Create Ticket').locator('i').first().click();
  await page.getByTitle('Tickets').click();
  await page.getByRole('link', { name: 'Dashboard' }).click();
  
  await page.getByRole('link', { name: 'Anchor Point (APT)' }).click();
  await expect(page.getByRole('heading', { name: 'Anchor Point (APT) Dashboard' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Renewal costs of assets' })).toBeVisible();
  await expect(page.locator('#tab_renewal_cost')).toContainText('Renewal costs of assets');
  //await page.keyboard.press('PageUp');
  await expect(page.getByRole('button', { name: 'Download PDF' })).toBeVisible();
  // download event
  const downloadPromise1 = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download PDF' }).click();
  const download1 = await downloadPromise1;
  await download1.saveAs('tests/download/' + download1.suggestedFilename());
  
  await page.getByRole('button', { name: 'Maintenance costs of assets' }).click();
  await expect(page.getByRole('button', { name: 'Maintenance costs of assets' })).toBeVisible();
  await expect(page.locator('#tab_maintenenance_cost')).toContainText('Maintenance costs of assets');
  //await page.keyboard.press('PageUp');
  await expect(page.getByRole('button', { name: 'Download PDF' })).toBeVisible();
  // download event
  const downloadPromise2 = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download PDF' }).click();
  const download2 = await downloadPromise2;
  await download2.saveAs('tests/download/' + download2.suggestedFilename());
  
  await expect(page.getByRole('button', { name: 'Annual Average Infrastructure' })).toBeVisible();
  await page.getByRole('button', { name: 'Annual Average Infrastructure' }).click();
  await expect(page.locator('#tab_annual_reserve')).toContainText('Annual Average Infrastructure Demand');
  //await page.keyboard.press('PageUp');
  await expect(page.getByRole('button', { name: 'Download PDF' })).toBeVisible();
  // download event
  const downloadPromise3 = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download PDF' }).click();
  const download3 = await downloadPromise3;
  await download3.saveAs('tests/download/' + download3.suggestedFilename());
  
  await expect(page.getByRole('button', { name: 'Risk By System' })).toBeVisible();
  await page.getByRole('button', { name: 'Risk By System' }).click();
  await expect(page.locator('#tab_system_risk_renewal')).toContainText('Risk By System');
  //await page.keyboard.press('PageUp');
  await expect(page.getByRole('button', { name: 'Download PDF' })).toBeVisible();
  // download event
  const downloadPromise4 = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download PDF' }).click();
  const download4 = await downloadPromise4;
  await download4.saveAs('tests/download/' + download4.suggestedFilename());
  
  await expect(page.getByRole('button', { name: 'Remaining Years by Renewal Cost by System' })).toBeVisible();
  await page.getByRole('button', { name: 'Remaining Years by Renewal Cost by System' }).click();
  await expect(page.locator('#tab_remaining_years_renewal_system')).toContainText('Remaining Years by Renewal Cost by System');
  //await page.keyboard.press('PageUp');
  await expect(page.getByRole('button', { name: 'Download PDF' })).toBeVisible();
  // download event
  const downloadPromise5 = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download PDF' }).click();
  const download5 = await downloadPromise5;
  await download5.saveAs('tests/download/' + download5.suggestedFilename());
  
  await expect(page.getByRole('button', { name: 'Remaining Years by Renewal Cost by Risk' })).toBeVisible();
  await page.getByRole('button', { name: 'Remaining Years by Renewal Cost by Risk' }).click();
  await page.locator('#container').click();
  await page.keyboard.press('PageUp');
  await expect(page.getByRole('button', { name: 'Download PDF' })).toBeVisible();
  // download event
  const downloadPromise6 = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download PDF' }).click();
  const download6 = await downloadPromise6;
  await download6.saveAs('tests/download/' + download6.suggestedFilename());
  
  await page.getByRole('heading', { name: 'Remaining Years by Renewal' }).click();
  await page.keyboard.press('PageUp');
  await expect(page.getByRole('button', { name: 'Download PDF' })).toBeVisible();
  // download event
  const downloadPromise7 = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download PDF' }).click();
  const download7 = await downloadPromise7;
  await download7.saveAs('tests/download/' + download7.suggestedFilename());
});