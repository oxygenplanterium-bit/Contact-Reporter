# Contact Reporter: one-time Supabase setup

Contact Reporter has its own Supabase project, separate from Nursery Manager. Create it once:

1. Go to supabase.com, sign in, and tap **New project**. Name it `contact-reporter`, choose any region near you, set a database password (save it somewhere) and create it. Wait until it finishes setting up.
2. Open **SQL Editor**, tap **New query**, paste the whole of `supabase.sql` from this repository, and tap **Run**. It should say "Success".
3. Open **Authentication**, then **Sign In / Providers** (or **Providers**), and open **Email**:
   - **Confirm email: OFF** (this is required, because people sign up with a phone number, not a real e-mail).
   - Make sure **Allow new users to sign up** is ON.
4. Open **Authentication**, then **Users**, then **Add user** and **Create new user**. Use the owner e-mail `oxygenplanterium@gmail.com` with a password of your choice, and tick **Auto Confirm User**. This is the owner login.
5. Open **Project Settings**, then **API**. Copy the **Project URL** and the **anon public** key. Put them in `src/config.js` (`SUPABASE_URL` and `SUPABASE_KEY`). The anon key is public by design: the database rules in `supabase.sql` protect the data.

## How people sign in
- **Owner:** the e-mail and password from step 4.
- **Everyone else:** taps **Create new account** on the sign-in screen and enters name, phone number and password. The account stays *Waiting for approval* until the owner approves it in the **Users** tab. The owner then assigns groups to it in the **Groups** tab.

## What each person can see
- **Owner:** everything.
- **Approved user:** only the groups assigned to them and their own calls and reports.
- **Not yet approved:** nothing except their own account record.

## SuperUsers (added later)

Run `supabase.sql` again in the SQL Editor (it is safe to run more than once). This switches on SuperUser reports. In the app, open Owner Mode, then Users, and tap **Make SuperUser** on an approved person. A SuperUser can see and share the reports of ordinary users and their own reports. Nobody except the owner and that SuperUser can see a SuperUser's reports.

## Subscriptions with UPI payment (added later)

Run `supabase.sql` again (safe to repeat). In Owner Mode open **Payments**, fill in your name, UPI ID, amount, days for each payment and free days for new people, tick "Subscription is switched on" and save. Then tap **Give Everyone 30 Days** so people approved earlier are not locked out.

When a person's time ends they see a payment screen with a UPI QR code. After paying they enter the UPI reference number and tap **I Have Paid**. You see it under Payments, check it against your UPI app, and tap **Confirm Payment** to give them the next period. You can also add days to anyone from the Users tab. The owner is never locked out.
