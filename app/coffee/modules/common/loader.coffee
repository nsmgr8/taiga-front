###
# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
# Copyright (C) 2014 Juan Francisco Alcántara <juanfran.alcantara@kaleidos.net>
# Copyright (C) 2014 Alejandro Alonso <alejandro.alonso@kaleidos.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: modules/common/loader.coffee
###

# FIXME: this code not follows any style and any good practices on coffeescript
# and it should be rewritten in coffeescript style classes.

taiga = @.taiga
sizeFormat = @.taiga.sizeFormat
timeout = @.taiga.timeout

module = angular.module("taigaCommon")

LoaderDirective = (tgLoader, $rootscope) ->
    link = ($scope, $el, $attrs) ->
        tgLoader.onStart () ->
            $(document.body).addClass("loader-active")
            $el.addClass("active")

        tgLoader.onEnd () ->
            $(document.body).removeClass("loader-active")
            $el.removeClass("active")

    return {
        link: link
    }

module.directive("tgLoader", ["tgLoader", "$rootScope", LoaderDirective])

Loader = ($rootscope) ->
    config = {
        minTime: 300
    }

    startLoadTime = 0
    requestCount = 0
    lastResponseDate = 0

    pageLoaded = (force = false) ->
        if startLoadTime
            timeoutValue = 0

            if !force
                endTime = new Date().getTime()
                diff = endTime - startLoadTime

                if diff < config.minTime
                    timeoutValue = config.minTime - diff

            timeout timeoutValue, ->
                $rootscope.$broadcast("loader:end")
                window.prerenderReady = true # Needed by Prerender Server

        startLoadTime = 0
        requestCount = 0
        lastResponseDate = 0

    autoClose = () ->
        maxAuto = 5000
        timeoutAuto = setTimeout (() ->
            pageLoaded()

            clearInterval(intervalAuto)
        ), maxAuto

        intervalAuto = setInterval (() ->
            if lastResponseDate && requestCount == 0
                pageLoaded()

                clearInterval(intervalAuto)
                clearTimeout(timeoutAuto)
        ), 50

    start = () ->
        startLoadTime = new Date().getTime()
        $rootscope.$broadcast("loader:start")

    return {
        pageLoaded: pageLoaded
        start: start
        startWithAutoClose: () ->
            start()
            autoClose()
        onStart: (fn) ->
            $rootscope.$on("loader:start", fn)

        onEnd: (fn) ->
            $rootscope.$on("loader:end", fn)

        logRequest: () ->
            requestCount++

        logResponse: () ->
            requestCount--
            lastResponseDate = new Date().getTime()
    }


Loader.$inject = ["$rootScope"]

module.factory("tgLoader", Loader)
