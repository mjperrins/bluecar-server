angular.module('app.routes', [])

.config(function($stateProvider, $urlRouterProvider) {

  // Ionic uses AngularUI Router which uses the concept of states
  // Learn more here: https://github.com/angular-ui/ui-router
  // Set up the various states which the app can be in.
  // Each state's controller can be found in controllers.js
  $stateProvider
    
  

      .state('blueCar.rentals', {
    url: '/rentals',
    views: {
      'side-menu21': {
        templateUrl: 'templates/rentals.html',
        controller: 'rentalsCtrl'
      }
    }
  })

  .state('blueCar.profile', {
    url: '/profile',
    views: {
      'side-menu21': {
        templateUrl: 'templates/profile.html',
        controller: 'profileCtrl'
      }
    }
  })

  .state('blueCar.settiings', {
    url: '/settings',
    views: {
      'side-menu21': {
        templateUrl: 'templates/settiings.html',
        controller: 'settiingsCtrl'
      }
    }
  })

  .state('blueCar', {
    url: '/cars',
    templateUrl: 'templates/blueCar.html',
    controller: 'blueCarCtrl'
  })

$urlRouterProvider.otherwise('/cars/rentals')

  

});