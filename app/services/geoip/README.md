# GeoIP / Mapbox integration

## Auth integration point

After a successful login (authorization):

1. Read the client's public IP: `request.remote_ip`
2. Resolve location: `Geoip::ResolveLocation.for(ip: request.remote_ip)` → returns `{ country:, city: }`
3. Use `country` and `city` as local variables (or in session); no database persistence.

**Example (in your login action):**

```ruby
location = Geoip::ResolveLocation.for(ip: request.remote_ip)
country = location[:country]
city = location[:city]
# use country, city as needed (e.g. in response, or session[:country] = country)
```

`POST /session` does this and returns `{ country:, city:, login_ip: }` in the response body.

The resolver is safe to call on every login: if Mapbox or the IP lookup fails, it returns nils and logs the error; login must not fail.
