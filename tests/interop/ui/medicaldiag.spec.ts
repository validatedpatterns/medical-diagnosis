import { test, expect } from '@playwright/test';

test.use({
  ignoreHTTPSErrors: true
});


test('medicaldiag: test routes and grafana dashboard', async ({ page }) => {
  await page.goto("<hub console url>");
  await page.getByLabel('Username *').fill('kubeadmin');
  await page.getByLabel('Password *').fill("<kubeadmin password>");
  await page.getByRole('button', { name: 'Log in' }).click();
  await page.goto('https://s3-rgw-openshift-storage.apps.<hub cluster name>/');
  await expect(page.getByText('<ID>anonymous</ID>')).toBeVisible();
  await page.goto('https://xraylab-grafana-route-xraylab-1.apps.<hub cluster name>/d/testimagesdashboard/xray-test-dashboard?orgId=1&refresh=5s')
  await expect(page.getByText('Test uploaded image')).toBeVisible();
  await expect(page.getByText('Test processed image')).toBeVisible();
  await expect(page.getByText('Test anonymized image')).toBeVisible();
  await expect(page).toHaveScreenshot();

});