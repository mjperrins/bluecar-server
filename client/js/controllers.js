angular.module('app.controllers', [])
  
.controller('rentalsCtrl', ['$scope', '$stateParams','$http','$ionicLoading', // The following is the constructor function for this page's controller. See https://docs.angularjs.org/guide/controller
// You can include any angular dependencies as parameters for this function
// TIP: Access Route Parameters for your page via $stateParams.parameterName
function ($scope, $stateParams,$http,$ionicLoading) {

    $scope.show = function() {
        $ionicLoading.show({
            template: 'Loading Cars...'
        });
    };

    $scope.hide = function(){
        $ionicLoading.hide();
    };

    $scope.show();
    $http.get("/api/cars").then(function(response) {

        $scope.cars = response.data;

        $scope.hide();
    },function(err){
        console.log(err);
        $scope.hide();
    });

}])
   
.controller('profileCtrl', ['$scope', '$stateParams', // The following is the constructor function for this page's controller. See https://docs.angularjs.org/guide/controller
// You can include any angular dependencies as parameters for this function
// TIP: Access Route Parameters for your page via $stateParams.parameterName
function ($scope, $stateParams) {


}])
   
.controller('settiingsCtrl', ['$scope', '$stateParams', // The following is the constructor function for this page's controller. See https://docs.angularjs.org/guide/controller
// You can include any angular dependencies as parameters for this function
// TIP: Access Route Parameters for your page via $stateParams.parameterName
function ($scope, $stateParams) {


}])
   
.controller('blueCarCtrl', ['$scope', '$stateParams', // The following is the constructor function for this page's controller. See https://docs.angularjs.org/guide/controller
// You can include any angular dependencies as parameters for this function
// TIP: Access Route Parameters for your page via $stateParams.parameterName
function ($scope, $stateParams) {


}])
 