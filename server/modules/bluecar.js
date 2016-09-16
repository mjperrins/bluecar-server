/*
 * Copyright 2016 IBM Corp.
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

// BlueCar Web Integration

module.exports = function(app, creds) {

	// Install a "/ping" route that returns "pong"
	app.get('/ping', function(req, res) {
		res.send('pong');
	});


	var router = app.loopback.Router();
	router.get('/ping', function(req, res) {
		res.send('pongaroo');
	});
	app.use(router);

};
