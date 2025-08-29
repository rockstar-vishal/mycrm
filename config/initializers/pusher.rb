require 'pusher'

Pusher.app_id = '1227034'
Pusher.key = CRMConfig.pusher_key
Pusher.secret = CRMConfig.pusher_secret
Pusher.cluster = 'ap2'
Pusher.encrypted = true