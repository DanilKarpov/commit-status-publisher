BS.PoolProject = {
  poolId : 0,
  projectId : 0,
  crossId : 0,
  showLastProjectWarning : false,
  showLastPoolWarning : false,
  poolName : "",
  projectName : "",
  associatedChildrenCount : 0,
  remainProjectCount : 0,
  associated : false,
  canBeDissociated : false
};
BS.AgentPoolEditDialog = OO.extend(BS.AbstractModalDialog, {

  bindEnterHandler: function(handler) {
    var self = this;
    $j(document).keyup(function(e) {
      if (e.which == 27) {
        self.unbindEnterHandler();
      }
    });
    $j(document).off("keydown.dialogEnter");
    BS.AbstractModalDialog.bindEnterHandler.call(self, handler)
  },

  unbindEnterHandler: function() {
    if (!this._enterHandler) return;
    $j(document).off("keydown.dialogEnter");
    this._enterHandler = null;
  },

  close: function(){
    this.unbindEnterHandler();
    BS.AbstractModalDialog.close.call(this);
  }
});

BS.AP = {
  agentKeywords: {},

  //// AGENT TYPES MANIPULATION \\\\
  clickOnAddAgentType: function (poolId, nearestElement) {
    BS.PopupDialog.show(nearestElement, "pool-agent-types-popup", poolId, function() {
      BS.AP.reloadBlocks();
    });
  },

  getAgtItem: function(poolId, agtId) {
    var crossId = "pool_" + poolId + "_agt_" + agtId;
    return $j("#row_"+crossId);
  },

  clickOnDropAgentCross: function(agtId, showMoveAgentToDefaultPoolWarning, agentName) {
    if (showMoveAgentToDefaultPoolWarning) {
      BS.MoveAgentToDefaultPoolDialog.showDialog(agtId, agentName);
    }
    else {
      this.doDropAgent(agtId);
    }
  },

  doDropAgent: function(agtId) {
    var params = "action=MoveAgentsAction&agt=" + agtId + "&pool=0";
    BS.Util.hide("drop-agt-" + agtId + "-cross");
    this.ajax("drop-agt-" + agtId + "-progress", params, BS.MoveAgentToDefaultPoolDialog);
  },


  //// PROJECTS MANIPULATION \\\\
  clickOnAssociateProjects: function (poolId, nearestElement) {
    BS.PopupDialog.show(nearestElement, "pool-projects-popup", poolId, function() {
      BS.AP.reloadBlocks();
    });
  },

  clickOnDropProjectCross: function (poolProject) {
    if (!poolProject.associated)
      return;
    if (poolProject.showLastPoolWarning) {
      BS.DissociateLastPoolDialog.showDialog(poolProject);
    } else if (poolProject.showLastProjectWarning && poolProject.associatedChildrenCount == 0) {
      BS.DissociateLastProjectDialog.showDialog(poolProject);
    } else if (poolProject.associatedChildrenCount > 0) {
      BS.DissociateParentWithChildren.showDialog(poolProject);
    } else if (poolProject.canBeDissociated){
      this.doDropProject(poolProject.poolId, poolProject.projectId, poolProject.crossId);
    }
  },

  doDropProject: function(poolId, projectId, crossId) {
    var urlParams = "action=ConfigureProjectsAction&pool=" + poolId + "&dissociatedProject=" + projectId;
    BS.Util.hide(crossId);
    this.ajax(crossId + "-progress", urlParams, BS.DissociateLastProjectDialog);
  },


  doDropProjectWithChildrenOption: function(poolProject, withChildren, dialog) {
    var dissociatedProjectParam = poolProject.canBeDissociated ? "dissociatedProject=" + poolProject.projectId : "";

    if (withChildren) {
      var selector = 'ul.pool-projects[data-pid="' + poolProject.poolId + '"] li[data-pid="' + poolProject.projectId + '"]';
      var mainDepth = $j(selector).first().attr('data-depth');
      $j(selector).nextUntil('[data-depth="' + mainDepth + '"]', '.canBeDissociated').each(function( index, value ) {
        dissociatedProjectParam += '&dissociatedProject=' + $j(value).attr('data-pid');
      });
    }

    var urlParams = "action=ConfigureProjectsAction&pool=" + poolProject.poolId + "&" + dissociatedProjectParam;
    BS.Util.hide(poolProject.crossId);
    this.ajax(poolProject.crossId + "-progress", urlParams, dialog);
  },


  //// UTILS \\\\
  getPoolBox: function(poolId) {
    return $j("#pool-name-" + poolId);
  },

  showSingularOrPlural: function(spanIdPrefix, count) {
    var singularId = spanIdPrefix + "-singular";
    var pluralId = spanIdPrefix + "-plural";
    if (count == 1) {
      BS.Util.show(singularId);
      BS.Util.hide(pluralId);
    }
    else {
      BS.Util.hide(singularId);
      BS.Util.show(pluralId);
    }
  },

  reloadUrl: function(){
    return window['base_uri'] + "/agentPools.html"
  },

  reloadBlocks: function(afterComplete){
    $('pool-boxes-container-refresh').refresh(null, null, function(){
      if (afterComplete != undefined) {
        afterComplete.call()
      }
    });
  },

  showArchivedProjects: function(){
    $j('#agentPools\\.hideArchivedProject').trigger("click");
  },

  ajax: function(progressId, params, dialog) {
    BS.Util.show(progressId);
    BS.ajaxRequest(window['base_uri'] + "/agentPools.html", {
      parameters: params,
      onComplete: function(transport) {
        if (dialog != undefined){
          BS.Util.hide(progressId);
        }
        var respXML = transport.responseXML;
        if (respXML) {
          var hasError = BS.XMLResponse.processErrors(respXML, {
            onAgentPoolActionError: function(elem) {
              alert(elem.firstChild.nodeValue);
            }
          });
          if (!hasError) {
            if (dialog != undefined){
              dialog.close();
            }
            var poolIdNode = respXML.documentElement.firstChild;
            if (poolIdNode && poolIdNode.nodeName == "pool-id") {
              var poolId = poolIdNode.textContent;
              BS.AP.reloadBlocks(function(){BS.AP.selectPool(poolId)});
            }
            else {
              BS.AP.reloadBlocks();
            }
          }
        }
      }
    });
  },

  moveToPool: function(poolId){
    var offset = $j("#" + poolId).offset();
    if (offset != undefined) {
      $j('html, body').animate({
                                 scrollTop: $j("#" + poolId).offset().top
                               }, 500);
    }
  },

  selectPool: function(poolId){
    var block = $j('#' + poolId);

    block.addClass('selected');
    if ($j('#actionMessage').text().indexOf("was created successfully")>-1){
      this.moveToPool(poolId);
    } else if (!this.isOnScreen(poolId)){
      this.moveToPool(poolId);
    }
    setTimeout(function() {
      block.addClass('fade');
    }, 5000);
  },

  expandPool: function(poolId){
    var el = $(poolId);

    if (el != undefined && el._block != undefined) {
      el._block.show();
    }
  },

  isOnScreen: function(selector){
    var element = document.getElementById(selector);
    if (element == undefined){
      return false;
    }
    var bounds = element.getBoundingClientRect();
    return bounds.top < window.innerHeight && bounds.bottom > 0;
  },

  getPoolName: function(poolId){
    var pool =  $j("#pool-name-" + poolId);
    return $j(pool).attr("data-poolName");
  },

  getPoolMinAgents: function(poolId){
    var pool =  $j("#pool-name-" + poolId);
    return $j(pool).attr("data-poolMinAgents");
  },

  getPoolMaxAgents: function(poolId){
    var pool =  $j("#pool-name-" + poolId);
    return $j(pool).attr("data-poolMaxAgents");
  },

  selectPoolOnPageLoad: function(hash){
    if (hash != undefined){
      var poolId = hash.substring(1);
      BS.AP.selectPool(poolId);
      BS.AP.moveToPool(poolId);
      BS.AP.expandPool(poolId);
    }
    if ("onhashchange" in window) {
      window.onhashchange = function () {
        BS.AP.selectPoolOnPageLoad(window.location.hash);
      }
    } else {
      var storedHash = window.location.hash;
      window.setInterval(function () {
        if (window.location.hash != storedHash) {
          storedHash = window.location.hash;
          BS.AP.selectPoolOnPageLoad(storedHash);
        }
      }, 500);
    }
  },

  updateBlock: function(poolId){
    var el = $(poolId);

    if (el._block != undefined) {
      BS.CollapsableBlocks.registerBlock(el._block, 'agentPoolsList');
      el._block._saveState = function(){
        if (!this.mustPersistState) return;
        var saved = "";
        for(var i in this._blocks) {
          saved += i + ":";
        }
        BS.ajaxRequest(window['base_uri'] + "/ajax.html", {
          parameters: "blocksType=" + this.blocksType + "&state=" + saved,
          onComplete:   function() {
            BS.AP.reloadBlocks();
          }
        });
      };
    }
  },

  //// ACTIONS \\\\
  confirmCreateNewPool: function() {
    var gatherParameters = function(dialog, poolNameRaw, minAgentsRaw, maxAgentsRaw) {
      var poolName = encodeURIComponent(poolNameRaw);
      var minAgents = encodeURIComponent(minAgentsRaw);
      var maxAgents = encodeURIComponent(maxAgentsRaw);
      return "action=CreateNewPoolAction&name=" + poolName + "&minAgents=" + minAgents + "&maxAgents=" + maxAgents;
    };

    BS.PoolNameDialog.showDialog("Create New Pool", "", 0, -1, gatherParameters, false);
  },

  confirmRenamePool: function(poolId) {
    var oldName = this.getPoolName(poolId);
    var oldMinAgents = this.getPoolMinAgents(poolId);
    var oldMaxAgents = this.getPoolMaxAgents(poolId);
    var title = "Update Pool \"" + oldName + "\"";

    var gatherParameters = function(dialog, poolNameRaw, minAgentsRaw, maxAgentsRaw) {
      var poolName = encodeURIComponent(poolNameRaw);
      var minAgents = encodeURIComponent(minAgentsRaw);
      var maxAgents = encodeURIComponent(maxAgentsRaw);
      return "action=UpdatePoolAction&pool=" + poolId + "&name=" + poolName + "&minAgents=" + minAgents + "&maxAgents=" + maxAgents;
    };

    BS.PoolNameDialog.showDialog(title, oldName, oldMinAgents, oldMaxAgents, gatherParameters, true);
  },

  confirmRemovePool: function(poolId) {
    var pool = this.getPoolBox(poolId);
    var poolName = this.getPoolName(poolId);
    var agents = pool.find(".agt.item.existent");
    var projects = pool.find(".pro.item.existent");

    BS.RemovePoolDialog.showDialog(poolId, poolName, agents, projects)
  }
};


BS.PoolNameDialog = OO.extend(BS.AgentPoolEditDialog, {
  getContainer: function() {
    return $("PoolNameDialog");
  },

  gatherParameters: function(dialog, poolName, minAgents, maxAgents) {},

  showDialog: function(title, poolName, minAgents, maxAgents, gatherParameters, rename) {
    this.gatherParameters = gatherParameters;
    $j("#MaxAgentsDialogCheckbox").change(function(){
      if ($j(this).prop("checked")){
        $j("#maxAgentsDiv").addClass('hidden');
      } else {
        $j("#maxAgentsDiv").removeClass('hidden');
      }
    });

    $("PoolNameDialogTitle").innerHTML = title.escapeHTML();
    $("PoolNameDialogInputField").value = poolName;
    $("MinAgentsDialogInputField").value = minAgents;
    $j("#MaxAgentsDialogCheckbox").prop('checked', maxAgents == '-1');
    if (maxAgents == '-1') {
      $("MaxAgentsDialogInputField").value = '';
      $j("#maxAgentsDiv").addClass('hidden');
    } else {
      $("MaxAgentsDialogInputField").value = maxAgents;
      $j("#maxAgentsDiv").removeClass('hidden');
    }
    $("PoolNameDialogSubmitButton").value = rename ? "Update Pool" : "Create Pool";


    this.showCentered();
    $("PoolNameDialogInputField").focus();
    $("PoolNameDialogInputField").select();

    this.bindEnterHandler(this.doIt.bind(this));
  },

  doIt: function() {
    var dialog = $j(this);
    var poolName = BS.Util.trimSpaces($("PoolNameDialogInputField").value);
    var minAgents = BS.Util.trimSpaces($("MinAgentsDialogInputField").value);
    var maxAgents;
    if ($j("#MaxAgentsDialogCheckbox").prop('checked')){
      maxAgents = '-1';
    } else {
      maxAgents = BS.Util.trimSpaces($("MaxAgentsDialogInputField").value);
      if (!$j.isNumeric(maxAgents) || maxAgents < 0){
        alert('"Max agents" must be a non-negative integer');
        return;
      }
    }
    BS.AP.ajax("agentPoolNameProgress", BS.PoolNameDialog.gatherParameters(dialog, poolName, minAgents, maxAgents), BS.PoolNameDialog);
  },

  toggleMaxAgentsTB: function(){
    alert();
  },

  close: function() {
    this.unbindEnterHandler();
    this.doClose();
  }

});


BS.RemovePoolDialog = OO.extend(BS.AgentPoolEditDialog, {
  getContainer: function() {
    return $("RemovePoolDialog");
  },

  poolIdToRemove: 0,

  showDialog: function(poolId, poolName, agents, projects) {
    this.poolIdToRemove = poolId;

    this.setupDialog(poolName, agents, projects);

    this.showCentered();
    this.bindEnterHandler(this.doIt.bind(this));
  },

  setupDialog: function(poolName, agents, projects) {
    $j("#remove-pool-name").text(poolName);
    $j("#remove-agents-number").text(agents.length);
    $j("#remove-projects-number").text(projects.length);
    BS.AP.showSingularOrPlural("remove-agents", agents.length);
    BS.AP.showSingularOrPlural("remove-projects", projects.length);

    if (agents.length) {
      $j("#remove-agents-message").show();
    }
    else {
      $j("#remove-agents-message").hide();
    }

    if (projects.length) {
      $j("#remove-projects-message").show();
    }
    else {
      $j("#remove-projects-message").hide();
    }
  },

  doIt: function() {
    BS.AP.ajax("agentPoolRemoveProgress", "action=RemovePoolAction&pool=" + BS.RemovePoolDialog.poolIdToRemove, BS.RemovePoolDialog);
  }
});


BS.DissociateLastProjectDialog = OO.extend(BS.AgentPoolEditDialog, {
  getContainer: function() {
    return $("DissociateLastProjectDialog");
  },

  _onConfirm: null,

  showDialog: function(poolProject) {
    this._onConfirm = function() {
      BS.AP.doDropProject(poolProject.poolId, poolProject.projectId, poolProject.crossId);
    };

    this.setupDialog(poolProject.poolName, poolProject.projectName);

    this.showCentered();
    this.bindEnterHandler(this.doIt.bind(this));
  },

  setupDialog: function(poolName, projectName) {
    $j("#dissociate-last-project-from-pool-name").text(poolName);
    $j("#dissociate-last-project-name").text(projectName);
  },

  doIt: function() {
    this.close();
    if (this._onConfirm) {
      this._onConfirm();
    }
  }

});

BS.DissociateLastPoolDialog = OO.extend(BS.AgentPoolEditDialog, {
  getContainer: function() {
    return $("DissociateLastPoolDialog");
  },

  _onConfirm: null,

  showDialog: function(poolProject) {
    this._onConfirm = function() {
      BS.AP.doDropProjectWithChildrenOption(poolProject, true, this);
    };

    this.setupDialog(poolProject.poolName, poolProject.projectName);

    this.showCentered();
    this.bindEnterHandler(this.doIt.bind(this));
  },

  setupDialog: function(poolName, projectName) {
    $j("#dissociate-last-pool-from-project-name").text(poolName);
    $j("#dissociate-last-pool-name").text(projectName);
  },

  doIt: function() {
    this.close();
    if (this._onConfirm) {
      this._onConfirm();
    }
  }

});

BS.DissociateParentWithChildren = OO.extend(BS.AgentPoolEditDialog, {
  getContainer: function() {
    return $("DissociateParentWithChildren");
  },

  _onConfirm: null,

  showDialog: function(poolProject) {
    let that = this;
    this._onConfirm = function() {
      var that2 = this;
      debugger;
      BS.AP.doDropProjectWithChildrenOption(poolProject, this.removeWithChildren(), BS.DissociateParentWithChildren);
    };

    this.setupDialog(poolProject);

    this.showCentered();
    this.bindEnterHandler(this.doIt.bind(this));
  },

  setupDialog: function(poolProject) {

    $j('#withChildren').attr('checked','checked');
    $j("span.remove-project-name").text(poolProject.projectName);
    $j("span.remove-from-pool-name").text(poolProject.poolName);

    if (poolProject.canBeDissociated) {
      $j('#withChildren').removeAttr('disabled');
      BS.DissociateParentWithChildren.updateStatusText();
    } else {
      $j('#withChildren').attr('disabled','disabled');
      $j('#removeChildrenOnlyDescription').css('display','block');
      $j('#removeWithChildrenDescription').css('display','none');
      $j('#removeWithoutChildrenDescription').css('display','none');
    }

    if (poolProject.associatedChildrenCount == poolProject.remainProjectCount && poolProject.showLastProjectWarning){
      $j('#removeLastProjectInChildrenWarning').css('display','block');
    }


  },

  updateStatusText: function(){
    var withChildren = BS.DissociateParentWithChildren.removeWithChildren();
    if (withChildren){
      $j('#removeWithChildrenDescription').css('display','block');
      $j('#removeWithoutChildrenDescription').css('display','none');
      $j('#removeChildrenOnlyDescription').css('display','none');
    } else {
      $j('#removeChildrenOnlyDescription').css('display','none');
      $j('#removeWithChildrenDescription').css('display','none');
      $j('#removeWithoutChildrenDescription').css('display','block');
    }
  },

  removeWithChildren: function(){
    return $j('#withChildren').prop('checked');
  },

  doIt: function() {
    this.close();
    if (this._onConfirm) {
      this._onConfirm();
    }
  }

});

BS.MoveAgentToDefaultPoolDialog = OO.extend(BS.AgentPoolEditDialog, {
  getContainer: function() {
    return $("MoveAgentToDefaultPoolDialog");
  },

  _onConfirm: null,

  showDialog: function(agtId, agentName) {
    this._onConfirm = function() {
      BS.AP.doDropAgent(agtId);
    };

    $j("#move-agent-to-default-pool-name").text(agentName);

    this.showCentered();
    this.bindEnterHandler(this.doIt.bind(this));
  },

  doIt: function() {
    this.close();
    if (this._onConfirm) {
      this._onConfirm();
    }
  }

});
