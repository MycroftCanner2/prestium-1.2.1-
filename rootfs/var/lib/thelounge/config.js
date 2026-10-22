"use strict";
// The Lounge configuration for Prestium (https://thelounge.chat/docs/configuration)
// - private mode, one pre-provisioned user "prestium" (per-boot random password and
//   login token, see /usr/local/sbin/prestium-thelounge-setup)
// - web UI on 127.0.0.1:9000 only
// - IRC only through i2pd client tunnels on 127.0.0.1 (the firewall lets the "thelounge"
//   user reach nothing else)
// - no link previews / prefetch, no uploads, no logs on disk, no identd/LDAP/WEBIRC
module.exports = {
	public: false,
	host: "127.0.0.1",
	port: 9000,
	bind: undefined,
	reverseProxy: false,
	maxHistory: 10000,
	https: {enable: false, key: "", certificate: "", ca: ""},
	theme: "default",
	prefetch: false,
	disableMediaPreview: true,
	prefetchStorage: false,
	prefetchMaxImageSize: 2048,
	prefetchMaxSearchSize: 50,
	prefetchTimeout: 5000,
	fileUpload: {enable: false, maxFileSize: 10240, baseUrl: null},
	transports: ["websocket", "polling"],
	leaveMessage: "",
	defaults: {
		name: "IRC2P",
		host: "127.0.0.1",
		port: 6668,
		password: "",
		tls: false,
		rejectUnauthorized: true,
		nick: "anon%%%%",
		username: "user",
		realname: "anon",
		join: "#i2p,#i2p-chat,#i2p-dev,#i2p-help",
		leaveMessage: "",
	},
	lockNetwork: false,
	messageStorage: [],
	storagePolicy: {enabled: false, maxAgeDays: 7, deletionPolicy: "statusOnly"},
	useHexIp: false,
	webirc: null,
	identd: {enable: false, port: 113},
	oidentd: null,
	ldap: {enable: false},
	debug: {ircFramework: false, raw: false},
};
