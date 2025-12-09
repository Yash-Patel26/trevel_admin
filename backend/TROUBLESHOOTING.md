# Troubleshooting Database Connection

Despite opening the AWS firewall (Security Group) content to `0.0.0.0/0` (everyone), your computer cannot reach the database.

## Possible Causes
1.  **Local Network Block**: Many corporate/school networks block Port 5432.
    -   *Try*: Connect via Mobile Hotspot.
2.  **ISP Block**: Some ISPs block database ports.
3.  **Database Status**: Is the database status "Available" in the AWS Console?
4.  **Endpoint**: Double check the endpoint in `.env`.

## What to do next?
1.  **Try later**: Sometimes DNS takes 10-15 mins to propagate.
2.  **Ignore for now**: You can likely still **DEPLOY** to App Runner. App Runner is inside AWS infrastructure and should reach the database fine.
    -   Go to [AWS App Runner Console](https://console.aws.amazon.com/apprunner).
    -   Set the `DATABASE_URL` in the service configuration to:
        `postgresql://postgres:MySuperSecretPassword123!@trevel-db-instance-1.cjec8qq8s4wq.eu-north-1.rds.amazonaws.com:5432/postgres`
    -   (Note: Use the *Instance Endpoint* `trevel-db-instance-1...` not the cluster one).

## Verification Command
Run this in your terminal to retry connection:
```powershell
npx prisma migrate deploy
```
