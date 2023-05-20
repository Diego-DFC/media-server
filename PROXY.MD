# Caddy Proxy Server

## Caddy Service File
```bash
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify

; User and group the process will run as.
User=felix
Group=users

#Path to needed environment variables for Cloudflare API and JWT Secret.
Environment=EMAIL=earl.texter@gmail.com
Environment=GITHUB_CLIENT_ID="CLIENTID"
Environment=GITHUB_CLIENT_SECRET=CLIENTSECRET
Environment=CLOUDFLARE_API_TOKEN="CLOUDAPIONLYTOKENFORDNS"
Environment=JWT_SHARED_KEY=RANDOMSHAREDKEY

; Use graceful shutdown with a reasonable timeout
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

; Always set "-root" to something safe in case it gets forgotten in the Caddyfile.
ExecStart=/opt/caddy/caddy run --environ --config /opt/caddy/Caddyfile
ExecReload=/opt/caddy/caddy reload --config /opt/caddy/Caddyfile
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

## Github Authentication

For now while Caddy updates the automated build process, I download from:

https://caddyserver.com/download

And pick the following plugins as I use CloudFlare and Github oAuth2:

- caddy-dns/cloudflare
- greenpau/caddy-security

There are documentation links on stepping through setup and configuration:

https://authp.github.io/docs/authenticate/oauth/backend-oauth2-0007-github

I use proxy entries for all my items behind and oAuth for my login validation.

## Caddy Plex Configuration

I use [Caddy](https://github.com/mholt/caddy) as a proxy server and if you want to use it with Plex, there is a very simple config below that I used. I have since removed this from my config to help simplify things.

My plex configuration in my CaddyFile as follows:

```bash
{
	email {env.EMAIL}
	storage file_system {
		root /opt/caddy/ssl
	}
	https_port 443
	order authenticate before respond
	order authorize before basicauth

	security {
		oauth identity provider github {env.GITHUB_CLIENT_ID} {env.GITHUB_CLIENT_SECRET}

		authentication portal myportal {
			crypto default token lifetime 172800
			crypto key sign-verify {env.JWT_SHARED_KEY}
			cookie domain domain.us
			enable identity provider github
			ui {
				links {
					"My Identity" "/whoami" icon "las la-user"
				}
			}

			transform user {
				match realm github
				match sub github.com/yourusernamehere
				action add role authp/admin
			}
		}

		authorization policy mypolicy {
			set auth url https://auth.domain.us/oauth2/github
			crypto key verify {env.JWT_SHARED_KEY}
			allow roles authp/admin authp/user
			validate bearer header
			inject headers with claims
		}
	}
}

plex.domain.us {
	tls {
		dns cloudflare {env.CLOUDFLARE_API_TOKEN}
	}
	reverse_proxy localhost:32400
	encode gzip
}

ombi.domain.us {
	tls {
		dns cloudflare {env.CLOUDFLARE_API_TOKEN}
	}
	reverse_proxy localhost:5000
	encode gzip
}

auth.domain.us {
	tls {
		dns cloudflare {env.CLOUDFLARE_API_TOKEN}
	}
	authenticate with myportal
}

apps.domain.us {
	tls {
		dns cloudflare {env.CLOUDFLARE_API_TOKEN}
	}

	encode gzip
	authorize with mypolicy
	reverse_proxy localhost:2812

	route /tautulli* {
		reverse_proxy localhost:8181
	}

	route /sonarr* {
		reverse_proxy localhost:8989
	}

	route /radarr* {
		reverse_proxy localhost:7878
	}

	route /bazarr* {
		reverse_proxy localhost:6767
	}

	route /nzbget* {
		reverse_proxy localhost:6789
	}

	route /jackett* {
		reverse_proxy localhost:9117
	}

	route /qbit* {
		uri strip_prefix /qbit
		reverse_proxy localhost:8080
	}
}
```

Plex also needs to have a few additional steps to be added so Caddy is used in all situations.

### Plex Configuration

Remote Access - Disable

```
Network - Custom server access URLs = https://<your-domain>:443
```
Network - Secure connections = Required

### Stopping Local Access
By default, Plex regardless of what override URL you set will still connect locally to 32400. To remove this, I use the second option of adding the option to the Preferences.xml. You need to stop Plex and add the line in near the end of your Preferences.xml

allowLocalhostOnly="1" 

UFW or other firewall:
- Deny port 32400 externally (Plex still pings over 32400, some clients may use 32400 by mistake despite 443 and 80 being set).
