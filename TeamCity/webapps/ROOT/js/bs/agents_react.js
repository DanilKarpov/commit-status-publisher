BS.AgentsReact = {

  _scheduled: false,

  _unsubscribe: undefined,

  pools: undefined,

  collapsedState: Object.create(null),

  _fetcherUpdate$: ReactUI.createSimpleStream(),

  setPoolCollapsedState: function(poolId, collapsed) {
    this.collapsedState[poolId] = !!collapsed
    this.dispatchAgentPoolsCollapsing(poolId, collapsed)
  },

  togglePoolCollapsedState: function(poolId) {
    this.collapsedState[poolId] = !this.collapsedState[poolId]
    this.dispatchAgentPoolsCollapsing(poolId, this.collapsedState[poolId])
  },

  collapseAll: function() {
    Object.keys(this.collapsedState).map(function(poolId) {
        this.collapsedState[poolId] = true
    }.bind(this))
    this.dispatchAgentPoolsCollapsing()
  },

  expandAll: function() {
    Object.keys(this.collapsedState).map(function(poolId) {
      this.collapsedState[poolId] = false
    }.bind(this))
    this.dispatchAgentPoolsCollapsing()
  },

  dispatchAgentPoolsCollapsing: function(poolId, expanded) {
    if (!ReactUI || !ReactUI.store || !ReactUI.store.dispatch) {
      return
    }

    var ADD_BLOCKS = 'ADD_BLOCKS'
    var REMOVE_BLOCKS = 'REMOVE_BLOCKS'
    var COLLAPSED_AGENT_POOLS = 'COLLAPSED_AGENT_POOLS'

    if (poolId) {
      return ReactUI.store.dispatch({
        type: expanded ? ADD_BLOCKS : REMOVE_BLOCKS,
        block: COLLAPSED_AGENT_POOLS,
        ids: [poolId]
      })
    }

    var collapsedPoolsIds = Object.keys(this.collapsedState).filter(function(poolId) {
      return this.collapsedState[poolId] === true
    }.bind(this)).map(function(id) { return parseInt(id, 10)})

    var expandedPoolsIds = Object.keys(this.collapsedState).filter(function(poolId) {
        return this.collapsedState[poolId] !== true
      }.bind(this)).map(function(id) { return parseInt(id, 10)})

      ReactUI.store.dispatch({
        type: ADD_BLOCKS,
        block: COLLAPSED_AGENT_POOLS,
        ids: collapsedPoolsIds
      })

      ReactUI.store.dispatch({
        type: REMOVE_BLOCKS,
        block: COLLAPSED_AGENT_POOLS,
        ids: expandedPoolsIds
      })
  },

  scheduleRefresh: function() {
    if (!this._scheduled) {
      this._scheduled = true;
      this.refreshIfPossible();
    }
  },

  refreshIfPossible: function() {
    if (BS.canReload()) {
      this._scheduled = false;
      $('agentsList').refresh();
    } else {
      setTimeout(function() {
        BS.AgentsReact.refreshIfPossible();
      }, 1000);
    }
  },

  groupByPools: function (key) {
    BS.AgentsReact.showLoader();
    BS.User.setBooleanProperty(key, !$('groupByPoolsCheckbox').checked, {
      afterComplete: function () {
        $('agentsList').refresh();
      }
    });
  },


  refreshTabCounters: function (locator, pageTabSelector) {
    $j.ajax({
      url: window['base_uri'] + "/app/rest/ui/agents?locator=" + locator,
      headers: {
        "Accept": "application/json; charset=utf-8",
        "Content-Type": "application/json; charset=utf-8"
      }
    }).done(function(data) {
      $j(pageTabSelector).find('.tabCounter').html(data.count);
    });
  },

  refreshFetcherData: function () {
    this._fetcherUpdate$.fire();
  },

  checkPools: function () {
    return $j.ajax({
      url: window['base_uri'] + "/app/rest/ui/agentPools?fields=agentPool(id,name)",
      headers: {
        "Accept": "application/json; charset=utf-8",
        "Content-Type": "application/json; charset=utf-8"
      }
    }).then(function(data) {
      var poolsStr = JSON.stringify(data);
      if (BS.AgentsReact.pools != undefined && poolsStr != BS.AgentsReact.pools){
        BS.AgentsReact.scheduleRefresh();
      }
      BS.AgentsReact.pools = poolsStr;
    });
  },

  refreshTabsCounters: function () {
    BS.AgentsReact.refreshTabCounters('defaultFilter:false,connected:true,authorized:true&fields=count','#registeredAgents_Tab');
    BS.AgentsReact.refreshTabCounters('defaultFilter:false,connected:false,authorized:true&fields=count','#unregisteredAgents_Tab');
    BS.AgentsReact.refreshTabCounters('defaultFilter:false,connected:any,authorized:false&fields=count','#unauthorizedAgents_Tab');
  },

  refreshContent: function () {
    BS.AgentsReact.scheduleRefresh();
  },

  getAgentsLocator: function () {
    return 'defaultFilter:false,connected:true,authorized:true';
  },

  getUnregisteredAgentsFetcherOptions: function (updatePeriod) {
    return {
      update$: this._fetcherUpdate$,
      updatePeriod: updatePeriod,
      locator: 'defaultFilter:false,connected:false,authorized:true'
    };
  },


  getUnauthorizedAgentsFetcherOptions: function (updatePeriod) {
    return {
      update$: this._fetcherUpdate$,
      updatePeriod: updatePeriod,
      locator: 'defaultFilter:false,connected:any,authorized:false'
    };
  },

  getFetcherOptions: function (updatePeriod) {
    return {
      update$: this._fetcherUpdate$,
      updatePeriod: updatePeriod,
      locator: this.getAgentsLocator()
    };
  },

  getAgentsRendererOptions: function (updatePeriod, poolId, dataProcessFn, locator, isFirst) {
    var poolFilter = function (agent) {
      return poolId == undefined || (agent.pool && agent.pool && agent.pool.id == poolId)
    };
    var agentFilter = function (agent) {
      return poolFilter(agent)
    };
    return {
      withBranch: true,
      withPath: true,
      withLoader: poolId === undefined,
      withPool: poolId === undefined,
      isFirst: isFirst,
      processFn: function (agents, dimensions) {
        var filtered = agents.filter(agentFilter);
        if (dataProcessFn !== undefined) {
          dataProcessFn.call(this, poolId, filtered);
        }
        var sorting = BS.AgentListSorting.getSortFunctionByName(dimensions.dimension);
        var sorted = [].concat(filtered);
        if (sorting === undefined){
          BS.Log.warn("Sorting dimension not found. Required: " + dimensions.dimension);
        } else {
          sorted.sort(sorting);
        }
        if (dimensions.descending){
          sorted.reverse();
        }
        return sorted;
      },
      updatePeriod: updatePeriod,
      locator: locator,
      withFetcher: false
    };
  },

  isAre: function (n) {
    return (n == 1 ? 'is' : 'are');
  },

  buildS: function (n) { //added this instead of common isS function is in isS function ruls should be more complicated, later will replace with some utils
    return (n == 1 ? 'build' : 'builds');
  },

  agentS: function (n) { //added this instead of common isS function is in isS function ruls should be more complicated, later will replace with some utils
    return (n == 1 ? 'agent' : 'agents');
  },

  getValueFromElements: function (selector) {
    var res = 0;
    $j(selector).each(function () {
      res += parseInt($j(this).val());
    });
    return res;
  },

  getPoolDescription: function (running, total) {
    if (running == total && running == 0) {
      return 'No agents found';
    }

    if (running == 0) {
      if (total == 1) return '1 agent is idle';
      return 'All ' + total + ' agents are idle';
    }
    if (running == total) {
      if (total == 1) return '1 agent is busy';
      return 'All ' + total + ' agents are busy';
    }

    var idle = (total - running);
    return '' + running + ' ' + this.buildS(running) + ' ' + this.isAre(running) + ' running, '
      + idle + ' ' + this.agentS(idle) + ' ' + this.isAre(idle) + ' idle';
  },

  getConnectedAgentsDescription: function (running, total) {
    if (total == 0) {
      return 'There are no connected agents.';
    }
    return 'There '+ this.isAre(total) + ' <b>' + total + '</b> available ' + this.agentS(total) + ' (<strong>' + running + '</strong> running ' + this.buildS(running) + ').';
  },

  getDisconnectedAgentsDescription: function (running, total) {
    if (total == 0) {
      return 'There are no disconnected agents.';
    }
    return 'There are <b>' + total + '</b> currently disconnected ' + this.agentS(total) + ".";
  },

  getUnauthorizedAgentsDescription: function (running, total, licenseLeft) {
    if (total == 0) {
      return 'There are no unauthorized agents.';
    }
    var licenses = '';
    if (licenseLeft != 0){
      licenses = ' Agent licenses left: <b>' + (licenseLeft == -1 ? 'unlimited' : licenseLeft) + '</b>.'
    }
    return 'There are <b>' + total + '</b> currently unauthorized ' + this.agentS(total) + "." + licenses;
  },

  getAgentsDescription: function (running, total, grouped, tabName) {
    if (tabName == 'registeredAgents'){
      //it means we are on connected agent tab
      if (total == 0) {
        return 'No agents found';
      }
      return '<b>' + total + '</b> ' + this.agentS(total) + ' (<strong>' + running + '</strong> running ' + this.buildS(running) + ')';
    } else {
      return '';
    }
  },

  showLoader: function () {
     BS.Util.show("groupByPoolsProgress");
  },

  hideLoader: function () {
     BS.Util.hide("groupByPoolsProgress");
  },

  subscribeOnStoreChange: function(locator, agentTabPage, actuallyGroupByPool, licenseLeft){
    if (BS.AgentsReact._unsubscribe != undefined){
      BS.AgentsReact._unsubscribe();
    }

    BS.AgentsReact._unsubscribe = ReactUI.onChange(
      function(state) {
        if (!ReactUI.getAgentsReady(state, locator, BS.AgentsReact.additionalFields)) {
          return null;
        }

        return ReactUI.getAgents(state, locator, BS.AgentsReact.additionalFields);
      },
      function(agents) {
        if (agents == null) {
          return;
        }

        BS.AgentsReact.updateAgentsDescription(agents, actuallyGroupByPool, agentTabPage, licenseLeft);
        if (agents.length > 0) {
          $j('#groupToolbar').css('display','block');
        }
      }
    );
  },

  updateAgentsDescription: function (agents, grouped, tabName, licenseLeft) {
    var total = agents.length, running = 0;
    agents.forEach(function (agent) {
      if ('build' in agent) {
        running++;
      }
    });
    $j('#installLinks').css('display', (total == 0 ? 'block' : 'none'));
    BS.AgentsReact.hideLoader();
    $j('#groupToolbar').css('display', (total > 0 ? 'block' : 'none'));
    $j('#sorter').css('display', (total > 1 ? 'inline-block' : 'none'));

    var description = '';
    if (tabName == 'registeredAgents'){
      description = BS.AgentsReact.getConnectedAgentsDescription(running, total);
    } else if (tabName == 'unregisteredAgents'){
      description = BS.AgentsReact.getDisconnectedAgentsDescription(running, total);
    } else if (tabName == 'unauthorizedAgents'){
      description = BS.AgentsReact.getUnauthorizedAgentsDescription(running, total, licenseLeft);
    }
    $j('#description').html(description);
  },

  getSorterDimensions: function(tabName, excludedDimensions){
    var shouldExcludeLastConnect = excludedDimensions.indexOf(BS.AgentListSorting.properties[2].name) >= 0;
    var dimensions = {dimensions: [
        BS.AgentListSorting.properties[1].name
    ]};

    switch (tabName) {
      case 'unregisteredAgents':
        dimensions.dimensions.push(
          BS.AgentListSorting.properties[4].name,
          BS.AgentListSorting.properties[5].name
        );
        !shouldExcludeLastConnect && dimensions.dimensions.push(BS.AgentListSorting.properties[2].name);
        break;
      case 'unauthorizedAgents':
        dimensions.dimensions.push(BS.AgentListSorting.properties[3].name);
        !shouldExcludeLastConnect && dimensions.dimensions.push(BS.AgentListSorting.properties[2].name);
        break;
      default:
        dimensions.dimensions.push(
          BS.AgentListSorting.properties[3].name,
          BS.AgentListSorting.properties[4].name
        );
    }

    return dimensions;
  },

  renderSorter: function(id, tabName, options){
    var excludedDimensions = [];

    if (options) {
      if (options.lastActivityTime === false) {
        excludedDimensions.push(BS.AgentListSorting.properties[2].name)
      }
    }

    var dimensions = BS.AgentsReact.getSorterDimensions(tabName, excludedDimensions);

    ReactUI.renderSorter(id, dimensions);
  }

};

BS.AgentListSorting = {
  BY_NAME: 1,
  BY_LAST_COMMUNICATION: 2,
  BY_STATE: 3,
  BY_ACTIVITY: 4,
  BY_INACTIVITY_REASON: 5,

  properties: {
    1: {name: "Agent name", value: 1, sortFn: function(a, b){
      return a.name.localeCompare(b.name);
    }},
    2: {name: "Last communication date", value: 2, sortFn: function(a, b){
      var dateFromString = function(str){
        var x = new Date();

        if (str) {
          x.setFullYear(str.substring(0,4));
          x.setMonth(str.substring(4,6));
          x.setDate(str.substring(6,8));
          x.setHours(str.substring(9,11));
          x.setMinutes(str.substring(11,13));
          x.setSeconds(str.substring(13,15));
        }

        return x;
      };
      var x = dateFromString(a.lastActivityTime).getTime();
      var y = dateFromString(b.lastActivityTime).getTime();
      return x === y ? 0 : (x > y ? -1 : 1);
    }},
    3: {name: "Enable / disable state", value: 3, sortFn: function(a, b){
      var x = a.enabled;
      var y = b.enabled;
      return x === y ? 0 : (x > y ? -1 : 1);
    }},
    4: {name: "Running build", value: 4, sortFn: function(a, b){
      var x = 'build' in a;
      var y = 'build' in b;
      return x === y ? 0 : (x > y ? -1 : 1);
    }},
    5: {name: "Agent inactivity reason", value: 5, sortFn: function(a, b){
      return a.disconnectionComment.localeCompare(b.disconnectionComment);
    }}
  },

  getSortFunctionByName: function (name){
    for (var i=1; i<6; i++){
      if (BS.AgentListSorting.properties[i].name === name){
        return BS.AgentListSorting.properties[i].sortFn;
      }
    }

    BS.Log.warn("Unknown dimension: " + name);

    return undefined;
  }
};
