import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json'
});

test('landing page', async ({ page }) => {
  await page.goto(url);

  await expect(page.locator('#banner')).toBeVisible();

  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');

  await expect(page.locator('#profile')).toContainText('An affordable, user friendly asset management platform for small communities. MyCivitas is an all-inclusive, easy to use platform that lets you record and manage your assets in one powerful information system.');

  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'MC MyCivitas' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'How Does MyCivitas Work?' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Pricing' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Our Story' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Documentation' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Community Map', exact: true })).toBeVisible();

  await expect(page.getByRole('link', { name: 'View Table' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Dashboard' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Work Orders' })).toBeVisible();

  await expect(page.locator('#profile-navbar')).toBeVisible();

  await page.getByRole('link', { name: 'How Does MyCivitas Work?' }).click();

  await expect(page.locator('#workflow-1')).toContainText('How does MyCivitas work?');

  await expect(page.locator('#workflow-1').getByRole('img').nth(1)).toBeVisible();

  await expect(page.locator('#workflow-1')).toContainText('The heart of MyCivitas is a map of your community and it\'s assets and infrastructure.');

  await expect(page.getByText('Keep scrolling to find out')).toBeVisible();

  await page.getByText('↓').click();

  await page.mouse.wheel(0, 300);

  await expect(page.locator('#workflow-2')).toContainText('Capture your infrastructure');

  await expect(page.locator('#workflow-2')).toContainText('Create an asset inventory using powerful mapping software. Our data capture system uses QGIS, a free and open source desktop application.');

  await expect(page.locator('#workflow-2').getByRole('img')).toBeVisible();

  await expect(page.locator('#workflow-2')).toContainText('Create an asset inventory using powerful mapping software. Our data capture system uses QGIS, a free and open source desktop application.');

  await page.mouse.wheel(0, 300);

  await expect(page.locator('#workflow-3')).toContainText('Prioritize Your Assets');

  await expect(page.locator('#workflow-3').getByRole('img')).toBeVisible();

  await expect(page.locator('#workflow-3')).toContainText('Our system performs risk assessment analysis and preventative maintenance planning analysis on your data.');

  await page.mouse.wheel(0, 300);

  await expect(page.locator('#workflow-4')).toContainText('Support Your Capital Planning');

  await expect(page.locator('#workflow-4').getByRole('img')).toBeVisible();

  await expect(page.locator('#workflow-4')).toContainText('Make informed decisions to support your capital planning.');

  await page.mouse.wheel(0, 300);

  await expect(page.locator('#workflow-5')).toContainText('Set Up Work Order');

  await expect(page.locator('#workflow-5').getByRole('img')).toBeVisible();

  await expect(page.locator('#workflow-5')).toContainText('Use the platform to plan ad hoc and scheduled maintenance planning tasks.');

  await page.mouse.wheel(0, 300);

  await expect(page.locator('#workflow-6')).toContainText('We Are Here to Help');

  await expect(page.locator('#workflow-6').getByRole('img')).toBeVisible();

  await expect(page.getByText('Let us know if you need any')).toBeVisible();

  await page.mouse.wheel(0, 300);

  await expect(page.locator('#workflow-7')).toContainText('Enjoy Asset Management');

  await expect(page.locator('#workflow-7').getByRole('img')).toBeVisible();

  await expect(page.locator('#workflow-7')).toContainText('Practice effective and sustainable asset management on our affordable platform to benefit of your community.');

  await page.getByRole('link', { name: 'Pricing' }).click();

  await expect(page.locator('#pricing')).toContainText('Pricing with small community in mind');

  await expect(page.locator('#pricing')).toContainText('Choose the number of staff that will be using the platform.');

  await expect(page.locator('#price-list')).toContainText('Diamond');

  await expect(page.locator('#price-list')).toContainText('✓ Allowing up to 0 users in the organisation.');

  await expect(page.locator('#price-list')).toContainText('Gold');

  await expect(page.locator('#price-list')).toContainText('✓ Allowing up to 0 users in the organisation.');

  await expect(page.locator('#price-list')).toContainText('Silver');

  await expect(page.locator('#price-list')).toContainText('✓ Allowing up to 0 users in the organisation.');

  await page.getByText('How Does MyCivitas Work? Pricing Our Story Documentation').click();

  await expect(page.locator('#our-story').getByRole('img')).toBeVisible();

  await expect(page.locator('#our-story')).toContainText('Our story');

  await expect(page.locator('#our-story')).toContainText('MyCivitas was created by LandInfo Technologies and Kartoza after we identified a need for an affordable and easy to use asset management system for small communities. The large proprietary offerings are overly complex and far too expensive for most small communities to be able to invest time into or afford.');

  await expect(page.locator('#our-story')).toContainText('Open Source');

  await expect(page.locator('#our-story')).toContainText('MyCivitas is Open Source software. This means that the intellectual property behind the platform is freely available to everyone and developed by a community of users who care about solving the problems you deal with every day in your small community.');

  await expect(page.locator('#our-story').getByRole('link', { name: 'LandInfo Technologies' })).toBeVisible();

  await expect(page.locator('#our-story').getByRole('link', { name: 'Kartoza' })).toBeVisible();
  
  await expect(page.getByRole('link', { name: 'freely available' })).toBeVisible();
});