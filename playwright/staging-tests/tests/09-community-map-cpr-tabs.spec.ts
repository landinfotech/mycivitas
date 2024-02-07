import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json',
  viewport: {
    height: 720,
    width: 1280
  }
});

test('test for community map "C", "P", "R"', async ({ page }) => {
  await page.goto(url);
  await expect(page.locator('#banner')).toBeVisible();
  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');
  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Community Map', exact: true })).toBeVisible();
  await page.getByRole('link', { name: 'Community Map', exact: true }).click();
  await page.waitForURL('**/community-map');
  await expect(page.getByLabel('Map')).toBeVisible();
  await expect(page.locator('#community')).toContainText('Anchor Point (APT)');
  await page.getByText('C This is message').click();
  await expect(page.locator('#consequence-of-failure > .title')).toBeVisible();
  await expect(page.locator('#consequence-of-failure canvas').first()).toBeVisible();
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 116,
      y: 13
    }
  });
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 215,
      y: 15
    }
  });
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 233,
      y: 34
    }
  });
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 124,
      y: 35
    }
  });
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 134,
      y: 34
    }
  });
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 232,
      y: 41
    }
  });
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 127,
      y: 17
    }
  });
  await page.locator('#consequence-of-failure canvas').first().click({
    position: {
      x: 206,
      y: 15
    }
  });
  await expect(page.locator('#consequence-of-failure canvas').nth(1)).toBeVisible();
  await page.locator('#consequence-of-failure canvas').nth(1).click({
    position: {
      x: 11,
      y: 20
    }
  });
  await page.locator('#consequence-of-failure canvas').nth(1).click({
    position: {
      x: 34,
      y: 10
    }
  });
  await page.locator('#consequence-of-failure canvas').nth(1).click({
    position: {
      x: 246,
      y: 14
    }
  });
  await page.locator('#consequence-of-failure canvas').nth(1).click({
    position: {
      x: 286,
      y: 157
    }
  });
  await page.getByText('P This is message').click();
  await expect(page.locator('#probability-of-failure > .title')).toBeVisible();
  await expect(page.locator('#probability-of-failure canvas').first()).toBeVisible();
  await page.locator('#probability-of-failure canvas').first().click({
    position: {
      x: 71,
      y: 15
    }
  });
  await page.locator('#probability-of-failure canvas').first().click({
    position: {
      x: 153,
      y: 15
    }
  });
  await page.locator('#probability-of-failure canvas').first().click({
    position: {
      x: 259,
      y: 12
    }
  });
  await page.locator('#probability-of-failure canvas').first().click({
    position: {
      x: 159,
      y: 14
    }
  });
  await page.locator('#probability-of-failure canvas').first().click({
    position: {
      x: 77,
      y: 10
    }
  });
  await page.locator('#probability-of-failure canvas').first().click({
    position: {
      x: 270,
      y: 16
    }
  });
  await page.locator('#probability-of-failure canvas').first().click({
    position: {
      x: 117,
      y: 265
    }
  });
  await expect(page.locator('#probability-of-failure canvas').nth(1)).toBeVisible();
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 15,
      y: 158
    }
  });
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 59,
      y: 162
    }
  });
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 171,
      y: 11
    }
  });
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 252,
      y: 20
    }
  });
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 268,
      y: 55
    }
  });
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 286,
      y: 47
    }
  });
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 52,
      y: 27
    }
  });
  await page.locator('#probability-of-failure canvas').nth(1).click({
    position: {
      x: 151,
      y: 169
    }
  });
  await page.getByText('R This is message').click();
  await expect(page.locator('#risk > .title')).toBeVisible();
  await expect(page.locator('#risk canvas').first()).toBeVisible();
  await page.locator('#risk canvas').first().click({
    position: {
      x: 72,
      y: 14
    }
  });
  await page.locator('#risk canvas').first().click({
    position: {
      x: 254,
      y: 14
    }
  });
  await page.locator('#risk canvas').first().click({
    position: {
      x: 168,
      y: 13
    }
  });
  await page.locator('#risk canvas').first().click({
    position: {
      x: 100,
      y: 13
    }
  });
  await page.locator('#risk canvas').first().click({
    position: {
      x: 172,
      y: 17
    }
  });
  await page.locator('#risk canvas').first().click({
    position: {
      x: 248,
      y: 14
    }
  });
  await page.locator('#risk canvas').first().click({
    position: {
      x: 57,
      y: 176
    }
  });
  await expect(page.locator('#risk canvas').nth(1)).toBeVisible();
  await page.locator('#risk canvas').nth(1).click({
    position: {
      x: 228,
      y: 145
    }
  });
  await page.locator('#risk canvas').nth(1).click({
    position: {
      x: 250,
      y: 164
    }
  });
  await page.locator('#risk canvas').nth(1).click({
    position: {
      x: 266,
      y: 16
    }
  });
  await page.locator('#risk canvas').nth(1).click({
    position: {
      x: 148,
      y: 12
    }
  });
  await page.locator('#risk canvas').nth(1).click({
    position: {
      x: 56,
      y: 27
    }
  });
  await page.locator('#risk canvas').nth(1).click({
    position: {
      x: 287,
      y: 160
    }
  });
  await expect(page.locator('#risk')).toContainText('Renewal Cost by Types');
  await expect(page.locator('#risk')).toContainText('Renewal Cost by Risk');
});