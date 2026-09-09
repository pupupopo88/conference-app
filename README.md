# README

## 日本語

[こちら](README_ja.md)

## About

Conference app is an app for (yes) conferences. The scope of this app is audiences and the interaction between them and organizers.

It's built with Ruby on Rails.

## Features

* Talk list
* Announcements
* Profile
* Push notification

## Planned features

* Anonymous Q&A for each talk
* Forum for each talk and the whole event

## Stack

The app is built with Ruby on Rails 8. It uses `jsbundling-rails` (with esbuild and pnpm), `turbo-rails`, `stimulus-rails` and `tailwindcss-rails` for front end development.

## Setup dev environment

### Setup user

#### Seed user login

Visit http://localhost:3000/login and you can login with the seed users. Note that this page is not linked from anywhere so you have to enter the URL manually.

#### GitHub login

##### Environment variables
See [`.env.sample`](.env.sample) for required/optional environment variables.

##### Create GitHub App
Current implementation requires GitHub App when you create a user.

<https://github.com/settings/apps/new>

* Callback URL: `http://localhost:3000/auth/github/callback`
* Webhook: inactive
* Permissions: Allow read-only access for "Organization permissions" -> "Members"

Then, fill these environment variables.

* App ID -> `GITHUB_APP_ID`
* Client ID -> `GITHUB_KEY`
* Client secret -> `GITHUB_SECRET`
* Private key (encoded) -> `GITHUB_PRIVATE_KEY` (See [`.env.sample`](.env.sample))

### Load seed data

```shell
$ bin/rails db:seed
```

After that, you can see event talks and speakers for 2023 and beyond.

- 2023: http://localhost:3000/2023/talks
- 2024: http://localhost:3000/2024/talks

## Setup dev environment with docker
```bash
$ cp .env.sample .env
```

Generate required environment variables
```bash
$ docker compose exec -it conference-app rails c

$ vapid_key = WebPush.generate_key
$ vapid_key.public_key
#=> "YOUR_PUBLIC_KEY"
$ vapid_key.private_key
#=> "YOUR_PRIVATE_KEY"
```

Copy to `.env`
```bash
VAPID_PUBLIC_KEY=YOUR_PUBLIC_KEY
VAPID_PRIVATE_KEY=YOUR_PRIVATE_KEY
```

And then execute below
```bash
$ docker compose up
$ docker compose exec conference-app rails db:prepare
```

### Generate sponsor visit URLs

Sponsor visit URLs use an HMAC token so that a URL for another sponsor cannot be guessed from the sponsor key. Generate a dedicated secret before creating URLs for QR codes.

```bash
$ openssl rand -hex 32
```

Set the generated value in `.env`.

```bash
SPONSOR_VISIT_TOKEN_SECRET=YOUR_GENERATED_SECRET
```

Restart the application after changing the secret.

```bash
$ docker compose restart conference-app
```

Organizers can open `/admin/sponsor_qr_codes` from the `Sponsor QR Codes` item in the admin menu. Use `Download PNG` beside each sponsor to save one file, or `Download all as ZIP` to save every QR code at once. Files inside the ZIP are named with each sponsor key so the recipients can be identified. Only sponsors with a `Booth` label are included.

Generate the sponsor names and stamp URLs for an event year with the following task:

```bash
$ docker compose exec conference-app bin/rails 'sponsors:stamp_urls[2026]'
```

The output can be used to create the QR codes placed at sponsor booths. Keep `SPONSOR_VISIT_TOKEN_SECRET` unchanged while the distributed QR codes are in use. The secret can be rotated for a new event year after the previous codes are no longer needed; rotating it invalidates all URLs generated with the old value.

## Acknowledgment
### Scout APM

![Scout APM logo](https://github.com/kaigionrails/conference-app/assets/4487291/7c300827-25ad-4fde-9f04-54a6419a3b61)

This app uses <https://scoutapm.com/> for performance monitoring.
