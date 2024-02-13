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

  await expect(page.getByLabel('Map')).toBeVisible();

  await expect(page.locator('#community')).toBeVisible();

  await expect(page.locator('div').filter({ hasText: /^Anchor Point \(APT\)$/ })).toBeVisible();

  await page.locator('#see-layer-list i').click();

  await page.locator('#hide-layer-list i').click();

  await page.locator('#see-layer-list i').click();

  await expect(page.getByText('Classification')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Structures Building' }).locator('a').click();

  await expect(page.locator('#Structures').getByRole('img')).toBeVisible();

  await expect(page.locator('#Structures_sub').getByText('Building')).toBeVisible();

  await expect(page.locator('#Structures_sub').getByText('Engineered Land')).toBeVisible();

  await expect(page.locator('#Structures_sub').getByText('Recreational Structure')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Structures Building' }).locator('a').click();

  await expect(page.locator('#asset_list div').filter({ hasText: 'Stormwater Collection Channel' }).locator('a')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Stormwater Collection Channel' }).locator('a').click();

  await expect(page.locator('#Stormwater-Collection').getByRole('img')).toBeVisible();

  await expect(page.locator('#Stormwater-Collection_sub').getByText('Channel')).toBeVisible();

  await expect(page.locator('#Stormwater-Collection_sub').getByText('Pipe')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Stormwater Collection Channel' }).locator('a').click();

  await page.locator('#asset_list div').filter({ hasText: 'Water Supply Control Hydrant' }).locator('a').click();

  await expect(page.locator('#Water-Supply').getByRole('img')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Control')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Hydrant')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Manhole Cover')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Manhole Trunk')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Motor')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Pipe')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Pump')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Treatment')).toBeVisible();

  await expect(page.locator('#Water-Supply_sub').getByText('Valve')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Water Supply Control Hydrant' }).locator('a').click();

  await page.locator('#asset_list div').filter({ hasText: 'Wastewater Collection Manhole' }).locator('a').click();

  await expect(page.locator('#Wastewater-Collection').getByRole('img')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Wastewater Collection Manhole' }).locator('a').click();

  await page.locator('#asset_list div').filter({ hasText: 'Wastewater Collection Manhole' }).locator('a').click();

  await expect(page.locator('#Wastewater-Collection_sub').getByText('Manhole Cover')).toBeVisible();

  await expect(page.locator('#Wastewater-Collection_sub').getByText('Manhole Trunk')).toBeVisible();

  await expect(page.locator('#Wastewater-Collection_sub').getByText('Pipe')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Wastewater Collection Manhole' }).locator('a').click();

  await page.locator('#asset_list div').filter({ hasText: 'Transportation Network' }).locator('a').click();

  await expect(page.locator('#Transportation-Network').getByRole('img')).toBeVisible();

  await expect(page.locator('#Transportation-Network_sub').getByText('Pedestrian Walkway')).toBeVisible();

  await expect(page.locator('#Transportation-Network_sub').getByText('Road Overlay')).toBeVisible();

  await page.locator('#asset_list div').filter({ hasText: 'Transportation Network' }).locator('a').click();

  await expect(page.locator('p').filter({ hasText: 'Risk' })).toBeVisible();

  await expect(page.locator('#risk_list div').filter({ hasText: 'Consequence of Failure' }).locator('a')).toBeVisible();

  await expect(page.locator('#risk_list').getByText('Probability of Failure')).toBeVisible();

  await expect(page.locator('#risk_list div').filter({ hasText: 'Risk' })).toBeVisible();

  await page.locator('#risk_list div').filter({ hasText: 'Consequence of Failure' }).getByRole('radio').check();

  await page.locator('#risk_list div').filter({ hasText: 'Consequence of Failure' }).locator('a').click();

  await expect(page.locator('#Consequence-of-Failure').getByRole('img')).toBeVisible();

  await page.getByText('Risk Consequence of Failure').click();

  await page.locator('#risk_list div').filter({ hasText: 'Consequence of Failure' }).locator('a').click();

  await page.locator('#risk_list div').filter({ hasText: 'Probability of Failure' }).getByRole('radio').check();

  await page.locator('#risk_list div').filter({ hasText: 'Probability of Failure' }).locator('a').click();

  await expect(page.locator('#Probability-of-Failure').getByRole('img')).toBeVisible();

  await page.locator('#risk_list div').filter({ hasText: 'Probability of Failure' }).locator('a').click();

  await page.locator('#risk_list div').filter({ hasText: 'Risk' }).getByRole('radio').check();

  await page.locator('#risk_list div').filter({ hasText: 'Risk' }).locator('a').click();

  await expect(page.locator('#Risk').getByRole('img')).toBeVisible();

  await page.locator('#risk_list div').filter({ hasText: 'Risk' }).locator('a').click();

  await expect(page.getByText('Organization')).toBeVisible();

  await expect(page.locator('#system_list').getByText('Buildings, Parks, and')).toBeVisible();

  await expect(page.locator('#system_list').getByText('Stormwater Collection')).toBeVisible();

  await expect(page.locator('#system_list').getByText('Transportation')).toBeVisible();

  await expect(page.locator('#system_list').getByText('Wastewater Collection and')).toBeVisible();

  await expect(page.locator('#system_list').getByText('Water Treatment and')).toBeVisible();

  await page.getByRole('button', { name: 'F' }).click();

  await page.getByRole('button', { name: 'L' }).click();

  await page.locator('#hide-layer-list i').click();

  await page.locator('#see-layer-list i').click();

  await page.locator('#risk_list div').filter({ hasText: 'Risk' }).getByRole('radio').check();

  await page.locator('#risk_list div').filter({ hasText: 'Consequence of Failure' }).getByRole('radio').check();

  await page.locator('#hide-layer-list i').click();

  await expect(page.getByText('Tickets', { exact: true })).toBeVisible();

  await expect(page.locator('#widget-ticket')).toContainText('Showing list of tickets that are opened.');

  await page.getByTitle('Assets').click();

  await expect(page.getByText('Assets', { exact: true })).toBeVisible();

  await expect(page.locator('#features-detail')).toContainText('This panel shows the assets that are selected in map.');

  await expect(page.getByText('Please click somewhere on the')).toBeVisible();

  await page.getByLabel('Map').click({
    position: {
      x: 676,
      y: 291
    }
  });

  await page.getByLabel('Map').click({
    position: {
      x: 655,
      y: 382
    }
  });

  await expect(page.getByText('Water Supply.Hydrant.59931')).toBeVisible();

  await expect(page.getByText('ID 59931')).toBeVisible();

  await expect(page.locator('#feature-59931')).toContainText('Add asset for creating ticket Remove asset from creating ticket');
});