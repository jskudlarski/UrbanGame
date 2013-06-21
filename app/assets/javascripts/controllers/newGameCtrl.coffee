###*Copyright 2013 BLStream, BLStream's Patronage Program Contributors
 *       http://blstream.github.com/UrbanGame/
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *       http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
###

# '------------------------------------- NEW GAME CTRL
newGameCtrl = app.controller 'newGameCtrl', ['$scope', '$location', '$route', '$rootScope', 'Games', 'Utilities', ($scope, $location, $route, $rootScope, Games, Utilities) ->
    
    # ------------------ INITIAL DATA FOR MODEL
    $scope.steps = [
        {no: 1, name: Messages("js.newgame.tab.step1title")},
        {no: 2, name: Messages("js.newgame.tab.step2title")},
        {no: 3, name: Messages("js.newgame.tab.step3title")},
        {no: 4, name: Messages("js.newgame.tab.step4title")}
    ]
    $scope.gameid = null
    $scope.previousname = null

    $scope.game = {
        name: "",
        description: "",
        location: "",
        startTime: "",
        startDate: null,
        endTime: "",
        endDate: null,
        winning: "max_points",
        winningNum: 1,
        diff: 'easy',
        playersNum: null,
        awards: "",
        tasksNo: 0,
        status: "project",
        version: 1
    }
    $scope.skin = {
        image: "games/gameicon.png"
    }
    $scope.error = null
    $scope.editable = true
    $scope.dateFormat = Messages("dateformatlong")

    # ------------------ MAP (task list)
    map = null
    overlays = []
    latlngBounds = null
    $scope.setMap = ->
        mapOptions = {
            zoom: 11,
            center: new google.maps.LatLng(51.107885, 17.038538),
            mapTypeId: google.maps.MapTypeId.ROADMAP
        }
        map = new google.maps.Map(document.getElementById("gpsMap"), mapOptions);
    
    $scope.showMarkers = (taskIndex) ->
        latlngBounds = new google.maps.LatLngBounds()
        overlay.setMap(null) for overlay in overlays
        overlays = []
        task = $scope.tasks[taskIndex]
        if task.type == "GPS"
            $scope.createMarker loc, task.name for loc in task.locations
            map.fitBounds(latlngBounds)
        else
            map.setCenter(new google.maps.LatLng(51.107885, 17.038538))
            map.setZoom(7)
                
    $scope.createMarker = (loc,taskName) ->
        marker = new google.maps.Marker {
            position: new google.maps.LatLng(loc.lat,loc.lng)
            }
        circle =  new google.maps.Circle {
            radius: loc.radius,
            strokeColor: "#000000",
            strokeOpacity: 1,
            strokeWeight: 1.5,
            fillColor: "#00FF00",
            fillOpacity: 0.45,
            center: marker.position
        }
        latlngBounds.extend(marker.position)
        overlays.push(marker)
        overlays.push(circle)
        circle.setMap(map)
        marker.setMap(map)
    
            
            
    
    # ------------------ EDIT MODE
    $scope.isEdit = ->
        if (/\/my\/games\/\d+\/edit/gi.test(window.location.pathname))
            $scope.gameid = parseInt(/(\d+)/.exec(window.location.pathname)[1])
            true
        else
            false


    fillGameModel = ->
        if $scope.isEdit()
            resource["get"]()

    $scope.tasks = [
        {name:"taskOne", type:"GPS", visible:"None", locations: [{lat:51.107885,lng:17.042338,radius:232},{lat:51.107885,lng:17.028538,radius:122}], version:1.0, maxPoints:7},
        {name:"taskTwo", type:"ABC", visible:"None", version:1.0, maxPoints:10},
        {name:"taskThree", type:"GPS", visible:"None", locations: [{lat:51.10235,lng:17.042328,radius:43},{lat:51.137885,lng:17.038538,radius:222}], version:1.0, maxPoints:7}
    ]


    loadModelData = (data) ->
        $scope.game = {
            name: data.name,
            description: data.description,
            location: data.location,
            startTime: new Date(data.startTime).toLocaleTimeString().substring(0,5),
            startDate: new Date(data.startTime),
            endTime: new Date(data.endTime).toLocaleTimeString().substring(0,5),
            endDate: new Date(data.endTime),
            winning: data.winning,
            winningNum: data.nWins,
            diff: data.difficulty,
            playersNum: if (data.maxPlayers == 1000000) then null else data.maxPlayers,
            awards: data.awards,
            tasksNo: data.tasksNo,
            status: data.status,
            version: data.version
        }

    # ------------------ UTILITY METHODS
    resource = {
        "get": ->
            Games.get(
                {gid: $scope.gameid},
                (data) ->
                    if data.status == 'published' || data.status == 'project'
                        loadModelData(data)
                        $scope.previousname=data.name
                        $scope.error = null
                        $scope.editable = true
                    else
                        window.location = "/my/games/" + $scope.gameid
                (error) ->
                    $scope.error = Messages("js.errors.ajax", "querying")
            )
        ,
        "publish": ->
            Games.publish(
                {data: $scope.gameid},
                (data) ->
                        window.location = "/my/games"
                (error) ->
                    $scope.error = Messages("js.errors.ajax", "publishing")
            )
        ,
        "save": ->
            Games.save(
                {data: $scope.game},
                (data) ->
                    $scope.gameid = data.val

                    if $scope.getCurrentStepIndex() == 3
                        window.location = "/my/games"
                    $scope.selection = $scope.steps[$scope.getCurrentStepIndex() + 1]
                    $scope.error = null
                (error) ->
                    $scope.error = Messages("js.errors.ajax", "saving")
            )
        ,
        "update": ->
            Games.update(
                {id: $scope.gameid, data: $scope.game},
                (data) ->
                    if $scope.getCurrentStepIndex() == 3
                        window.location = "/my/games"
                    $scope.selection = $scope.steps[$scope.getCurrentStepIndex() + 1]
                    $scope.stepSwitchedActions()
                    $scope.error = null
                (error) ->
                    $scope.error = Messages("js.errors.ajax", "updating")
            )
        ,
        "checkName": ->
            $("#processing").removeClass("img-ok img-error").addClass("img-processing")
            Games.checkName(
                {data: $scope.game.name},
                (result) ->
                    if result.val
                        $("#processing").removeClass("img-processing").addClass("img-ok")
                        $scope.form.$setValidity "nameunique", true
                    else
                        $("#processing").removeClass("img-processing").addClass("img-error")
                        $scope.form.$setValidity "nameunique", false
                    $scope.error = null
                (error) ->
                    $scope.error = Messages("js.errors.name") + error
            )
    }

    # ------------------ BUTTONS ACTIONS HANDLING
    $scope.savegame = ->
        gid = $scope.gameid

        if $scope.game.playersNum == null
            $scope.game.playersNum = 1000000
            notSetByUser = true 

        if (gid == null || _.isUndefined(gid))
            resource["save"]()
        else
            resource["update"]()

        if notSetByUser
            $scope.game.playersNum = null

    $scope.publishgame = ->
        gid = $scope.gameid
        action = "publish"

        if (gid != null && !_.isUndefined(gid))
            Utilities.showDialog($scope.game.name, action)
                .then (result) ->
                    if(result == "ok")
                        resource[action]()

    # ------------------ GAME NAME VALIDATION
    $scope.isValidName = ->
        if ($scope.gameid == null || _.isUndefined($scope.gameid))
            resource["checkName"]()

    # ------------------ STEPS SWITCHING
    $scope.stepSwitchedActions = ->
        if ($scope.getCurrentStepIndex()==0)
            $scope.onTab1Switch()
        else 
            if ($scope.getCurrentStepIndex()==1)
                $scope.onTab2Switch()
                
    $scope.selection = $scope.steps[0]

    $scope.getCurrentStepIndex = ->
        _.indexOf($scope.steps, $scope.selection)

    $scope.isDisabled = (index) ->
        true if ((index > $scope.getCurrentStepIndex()+1) || ($scope.form.$invalid && index > $scope.getCurrentStepIndex()))

    $scope.isLast = ->
        !$scope.hasNextStep()
        
    $scope.goToStep = (index) ->
            $scope.selection = $scope.steps[index] if !_.isUndefined($scope.steps[index])
            $scope.stepSwitchedActions()
            
    $scope.hasNextStep = ->
        stepIndex = $scope.getCurrentStepIndex()
        nextStep = stepIndex + 1
        !_.isUndefined($scope.steps[nextStep])

    $scope.hasPreviousStep = ->
        stepIndex = $scope.getCurrentStepIndex()
        previousStep = stepIndex - 1
        !_.isUndefined($scope.steps[previousStep])

    $scope.incrementStepIfValid = ->
        $scope.incrementStep() if !$scope.form.$invalid
    
    $scope.incrementStep = ->
        (
            stepIndex = $scope.getCurrentStepIndex()
            if stepIndex == 0
                $scope.game.location = $("#locationInput").val()
                $scope.savegame()
            else
                if stepIndex == 1
                    !$scope.geolocationBound = false
                nextStep = stepIndex + 1
                $scope.selection = $scope.steps[nextStep]
                $scope.stepSwitchedActions()
        ) if $scope.hasNextStep()
        
    $scope.decrementStep = ->
        (
            stepIndex = $scope.getCurrentStepIndex()
            previousStep = stepIndex - 1
            $scope.selection = $scope.steps[previousStep]
            $scope.stepSwitchedActions()

        ) if $scope.hasPreviousStep()

    # ------------------ PLAYERS ENUMERATOR
    $scope.incrementPlayersNum = ->
        if  $scope.game.playersNum == null
            $scope.game.playersNum = 2
        else
            $scope.game.playersNum += 1
        
    $scope.decrementPlayersNum = ->
        if $scope.game.playersNum > 2
            $scope.game.playersNum -= 1  
        else 
            $scope.game.playersNum = null
        
    $scope.incrementWinningNum = ->
        $scope.game.winningNum += 1
   
    $scope.decrementWinningNum = ->
        $scope.game.winningNum -= 1 if $scope.game.winningNum > 1
        
    $scope.timezone = "GMT" + ((if new Date().getTimezoneOffset() > 0 then "" else "+")) + (new Date().getTimezoneOffset() / (-60))

    $scope.gameduration = ->
        if !$scope.isEdit()
            sdate = new Date($scope.game.startDate.toDateString() + " " + $scope.game.startTime)
            edate = new Date($scope.game.endDate.toDateString() + " " + $scope.game.endTime)
        else
            sdate = $scope.game.startDate
            edate = $scope.game.endDate
        Utilities.difference(sdate, edate, false)

    $scope.getWinStrMsg = ->
        if $scope.game.winning == 'max_points'
            Messages("newgame.gametype1")
        else
            Messages("newgame.gametype2")
    
    $scope.onTab1Switch = ->
        setTimeout (->
            $("#locationInput").on 'click', -> 
                if (!$scope.geolocationBound) 
                    $("#locationInput").geocomplete types: ['(cities)']
                    $scope.geolocationBound=true
            $("#nameInput").on 'keyup', ->
                if $scope.game.name!=undefined
                    $scope.isValidName()
            $("#startTime, #startDate, #endTime, #endDate").bind 'input blur', (event)->
                if $scope.game.startDate instanceof Date && $scope.game.endDate instanceof Date && $scope.form.gStartTime.$valid && $scope.form.gEndTime.$valid
                    from = new Date($scope.game.startDate.getTime())
                    to = new Date($scope.game.endDate.getTime())
                    from.setHours(parseInt($scope.game.startTime.split(":")[0]),parseInt($scope.game.startTime.split(":")[1]))
                    to.setHours(parseInt($scope.game.endTime.split(":")[0]),parseInt($scope.game.endTime.split(":")[1]))
                    if from.getTime()>to.getTime()
                        $scope.form.$setValidity "dates", false
                    else
                        $scope.form.$setValidity "dates", true
                else
                    $scope.form.$setValidity "dates", true
        ), 200
        
    $scope.onTab2Switch = ->
        setTimeout (->
            $scope.setMap()
            ), 200

    # ------------------ INIT
    fillGameModel()

    # ------------------ WATCH
    $scope.$watch '[game.winningNum, game.playersNum]', ->
        if _.isUndefined($scope.game.winningNum)
            $scope.form.$setValidity "morewinnersthanplayers", false
        else
            if ($scope.game.playersNum != null)
                if ($scope.game.playersNum > $scope.game.winningNum)
                    $scope.form.$setValidity "morewinnersthanplayers", true
                else
                    $scope.form.$setValidity "morewinnersthanplayers", false
            else
                $scope.form.$setValidity "morewinnersthanplayers", true
    , true
        
    $ ->
        $scope.onTab1Switch()
        $scope.setMap()
        
    
]

time_regexp = /^(20|21|22|23|[01]\d|\d)(:[0-5]\d)$/

app.directive 'time', ->
    require: "ngModel"
    link: (scope, elm, attr, ctrl) ->
        ctrl.$parsers.unshift (viewValue) ->
            if (time_regexp.test(viewValue))
                ctrl.$setValidity "time", true
                viewValue
            else
                ctrl.$setValidity "time", false
                undefined

            

