import { test, expect } from '@playwright/test';

let url = '/';

test.use({
  storageState: 'auth.json',
  viewport: {
    height: 720,
    width: 1280
  }
});

test('test for dashboard list', async ({ page }) => {
  await page.goto(url);

  await expect(page.locator('#banner')).toBeVisible();

  await expect(page.locator('#profile')).toContainText('Welcome to MyCivitas');

  await expect(page.locator('#profile')).toContainText('An affordable, user friendly asset management platform for small communities. MyCivitas is an all-inclusive, easy to use platform that lets you record and manage your assets in one powerful information system.');

  await expect(page.getByRole('button', { name: 'Open Community Map' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Dashboard' })).toBeVisible();

  await page.getByRole('link', { name: 'Dashboard' }).click();

  await page.waitForURL('**/dashboard/list/')

  await expect(page.getByRole('heading')).toContainText('List of Linked Communities');

  await expect(page.getByRole('link', { name: 'Anchor Point (APT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Badger (BDR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Bay L\'Argent (BLA)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Belcarra (BEL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Birchy Bay (BRB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Bishop\'s Falls (BSF)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Brent\'s Cove (BRE)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Brighton (BRI)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Bryant\'s Cove (BRC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Buchans (BUC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Burgeo (BUR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Campbellton (CAM)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Cape Broyle (BRO)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Cartwright (CRT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Centreville-Wareham-Trinity (' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Change Islands (CHI)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Chapel Arm (CPL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Clarenville (CLN)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Come By Chance (CBC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Conception Harbour (CHB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Cormack (COR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Cox\'s Cove (COX)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Daniel\'s Harbour (DAH)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Dover (DOV)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Eastport (EAS)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Enderby (EDB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Fleur de Lys (FDL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Flower\'s Cove (FLC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Fox Cove-Mortier (FCM)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Frenchman\'s Cove (FRC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Fruitvale (FVE)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Gambo (GAM)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Garnish (GAR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'George\'s Brook-Millton (GBM)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Gillams (GIL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Hant\'s Harbour (HAH)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Happy Valley-Goose Bay (HVG)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Harbour Main-Chapel\'s Cove-' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Hawke\'s Bay (HAB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Heart\'s Content (HEC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Heart\'s Delight-Islington (' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Heart\'s Desire (HED)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Howley (HOW)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Hughes Brook (HUG)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Irishtown-Summerside (ITS)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Kaleden (KAL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Kaslo (KAS)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'King\'s Point (KPT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Lark Harbour (LARK)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'La Scie (LSC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Leading Tickles (136)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Lewin\'s Cove (LWC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Lewisporte (LEW)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Little Burnt Bay (LBB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Lockeport (LKP)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Long Harbour-Mount Arlington' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Lumby (LBY)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Lushes Bight-Beaumont-' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Mahone Bay (MHB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Montrose (MTE)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Mount Moriah (MTM)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Nakusp (NKP)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'New Denver (NDV)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'New Perlican (NPE)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'New-Wes-Valley (NWV)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Norman\'s Cove-Long Cove (NCL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Northern Arm (NOA)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'North West River (NWR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Old Perlican (ODPR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Parson\'s Pond (PAP)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Pasadena (PAS)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Port au Choix (PAC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Port au Port West-Aguathuna-' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Port au Port West-Aguathuna-' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Port Hawkesbury (PHK)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Port Rexton (PRX)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Port Saunders (NLPS)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Portugal Cove South (PCS)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Reidville (REI)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Rencontre East (REN)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'River of Ponds (ROP)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Riverport (RIV)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Robert\'s Arm (RBA)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Salmon Cove (SAL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Seal Cove (SLC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Silverton (SVT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Slocan (SCN)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Slocan Park Improvement' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Spaniard\'s Bay (SPB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'St. Jacques-Coomb\'s Cove (JCC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'St. Lawrence (SLW)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Terrenceville (TRV)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Three Rivers (TTR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Traytown (TRT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Trinity (TRN)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Trinity Bay North (TBN)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Triton (TRI)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Upper Island Cove (UPC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Vestman (LIT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Victoria (VIC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Victoria County (VTC)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Wabush (WAB)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Warfield (WFD)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Wellington (WLT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Whitbourne (WHT)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Whiteway (WHW)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Winterland (NLWTL)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Winterton (WTR)' })).toBeVisible();

  await expect(page.getByRole('link', { name: 'Woody Point (WOP)' })).toBeVisible();
  
  await expect(page.getByRole('link', { name: 'York Harbour (YRK)' })).toBeVisible();
});