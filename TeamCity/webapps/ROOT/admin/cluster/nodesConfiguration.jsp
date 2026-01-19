<%@ taglib prefix="forms" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ page import="jetbrains.buildServer.serverSide.NodeResponsibility" %>
<%@ page import="jetbrains.buildServer.serverSide.NodeResponsibilityProperties" %>
<%@ page import="jetbrains.buildServer.serverSide.impl.CommandLineNodeConfig" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="teamcityNodes" type="java.util.List<jetbrains.buildServer.serverSide.TeamCityNode>" scope="request"/>
<jsp:useBean id="filteredSupportedResps" type="java.util.Map<java.lang.String, jetbrains.buildServer.serverSide.NodeResponsibility>" scope="request"/>
<jsp:useBean id="currentNodeId" type="java.lang.String" scope="request"/>
<jsp:useBean id="buildsStats" type="java.util.Map<java.lang.String, jetbrains.buildServer.serverSide.impl.NodeStats.BuildsStats>" scope="request"/>
<jsp:useBean id="vcsPollingStats" type="java.util.Map<java.lang.String, jetbrains.buildServer.serverSide.impl.NodeStats.VcsPollingStats>" scope="request"/>
<jsp:useBean id="totalRunning" type="java.lang.Integer" scope="request"/>
<jsp:useBean id="triggersStats" type="java.util.List<jetbrains.buildServer.serverSide.impl.NodeStats.TriggerTypeInfo>" scope="request"/>
<jsp:useBean id="balancingInProgress" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="missingResponsibilities" type="java.util.List<jetbrains.buildServer.serverSide.NodeResponsibility>" scope="request"/>

<c:set var="processBuildMessagesResp" value="<%=NodeResponsibility.CAN_PROCESS_BUILD_MESSAGES%>"/>
<c:set var="checkForChangesResp" value="<%=NodeResponsibility.CAN_CHECK_FOR_CHANGES%>"/>
<c:set var="processBuildTriggersResp" value="<%=NodeResponsibility.CAN_PROCESS_BUILD_TRIGGERS%>"/>
<c:set var="mainServerResp" value="<%=NodeResponsibility.MAIN_NODE%>"/>
<c:set var="processUsersRequestsResp" value="<%=NodeResponsibility.CAN_PROCESS_USER_DATA_MODIFICATION_REQUESTS%>"/>
<c:set var="usersRoutingGroupKeysPropName" value="<%=NodeResponsibilityProperties.USER_REQUESTS_GROUP_KEYS_PROP%>"/>
<c:set var="nodeResponsibilitiesConfigDescription"><%= CommandLineNodeConfig.getConfigurationDescription() %></c:set>
<c:set var="canEditMainNodeResps" value="${fn:length(teamcityNodes) gt 1}"/>

<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.SUser" scope="request"/>

<bs:linkCSS>
  /css/forms.css
</bs:linkCSS>
<script type="text/javascript">

  BS.ProcessBuildMessagesSettings = OO.extend(BS.AbstractModalDialog, {
    getContainer: function() {
      return $('processBuildMessagesSettingsDialog');
    },

    save: function() {
      BS.Util.hide('.error');
      BS.blockRefreshPermanently("setResponsibilityProperty");
      BS.ajaxRequest(BS.ClusterAdmin.url, {
        parameters: BS.Util.serializeForm($('processBuildMessagesSettings')),
        onComplete: function (transport) {
          let errors = BS.XMLResponse.processErrors(transport.responseXML, {
            onPercentageLimitError: function(elem) {
              BS.Util.show("percentageLimit_error");
              $j("#percentageLimit_error").text(elem.firstChild.nodeValue);
            }
          }, function(elem) {
            BS.Util.show("processBuildMessagesSettings_error");
            $j("#processBuildMessagesSettings_error").text(elem.firstChild.nodeValue);
          });

          if (!errors) {
            BS.unblockRefresh("setResponsibilityProperty");
            $('nodesData').refresh();
            BS.ProcessBuildMessagesSettings.close();
          }
        }
      });

      return false;
    },
    show: function(nodeId, percentageLimit) {
      let that = this;
      BS.Util.hide($j('.error'));
      $j('#processBuildMessagesSettings_nodeId').val(nodeId);
      $j(that.getContainer()).find('.dialogTitle').text("Limit builds running on " + nodeId);
      $j('#percentageLimitInput').val(percentageLimit);
      this.showCentered();
    }
  });

BS.ClusterAdmin = {
  url: window['base_uri'] + "/admin/action.html",

  setNodeResponsibilityEnabled: function(elemId, nodeId, responsibilityName, enabled) {
    var action = function() {
      $j("span.error").text('');
      $j(elemId).hide();
      $j(elemId + '_progress').show();
      BS.blockRefreshPermanently("responsibilityChange");
      BS.ajaxRequest(BS.ClusterAdmin.url, {
        parameters: '&nodeId=' + nodeId + "&actionName=" + (enabled ? 'enableResponsibility' : 'disableResponsibility') + '&nodeResponsibility=' + responsibilityName,
        onComplete: function (transport) {
          var errors = BS.XMLResponse.processErrors(transport.responseXML, {
            toggleNodeStatusFailed: function(elem) {
              $j("span.error").text(elem.firstChild.nodeValue);
            },

            nodeTestConnectionFailed: function(elem) {
              $j("span.error").text(elem.firstChild.nodeValue + "\n" + "\nPlease check the node is up and running.");
            }
          });

          if (!errors) {
            BS.unblockRefresh("responsibilityChange");
            $('nodesData').refresh();
          } else {
            $j(elemId + '_progress').hide();
            $j(elemId).show();
          }
        }
      });
    };

    if (responsibilityName == '${processBuildMessagesResp.name()}') {
      if (enabled) {
        BS.confirmDialog.show({
          text: 'Enabling of the "${processBuildMessagesResp.displayName}" responsibility will add "' + nodeId + '" node to the list of nodes that process the data from the newly started builds.' +
            '<p><strong>Note</strong>: the already running builds will finish on the nodes they have been assigned to.</p>',
          title: "Enable responsibility",
          actionButtonText:  "Enable",
          cancelButtonText: 'Cancel',
          action: action
        });
      } else {
        BS.confirmDialog.show({
          text: 'Disabling of the "${processBuildMessagesResp.displayName}" responsibility will remove "' + nodeId + '" node from the list of nodes that process the data from the newly started builds.' +
            '<p><strong>Note</strong>: the already running builds will finish on the nodes they have been assigned to.</p>',
          title: "Disable responsibility",
          actionButtonText:  "Disable",
          cancelButtonText: 'Cancel',
          action: action
        });
      }
    } else if (responsibilityName == '${checkForChangesResp.name()}') {
      if (enabled) {
        BS.confirmDialog.show({
          text: 'Enabling of the "${checkForChangesResp.displayName}" responsibility will add "' + nodeId + '" node to the list of nodes executing the VCS polling and commit hooks tasks.',
          title: "Enable responsibility",
          actionButtonText:  "Enable",
          cancelButtonText: 'Cancel',
          action: action
        });
      } else {
        BS.confirmDialog.show({
          text: 'Disabling of the "${checkForChangesResp.displayName}" responsibility will remove "' + nodeId + '" node from the list of nodes executing the VCS polling and commit hooks tasks.' +
                '<p><strong>Warning</strong>: new builds cannot start if no TeamCity nodes have the "${checkForChangesResp.displayName}" responsibility.',
          title: "Disable responsibility",
          actionButtonText:  "Disable",
          cancelButtonText: 'Cancel',
          action: action
        });
      }
    } else if (responsibilityName == '${processBuildTriggersResp.name()}') {
      if (enabled) {
        BS.confirmDialog.show({
          text: 'Enabling of the "${processBuildTriggersResp.displayName}" responsibility will add "' + nodeId + '" node to the list of nodes processing the build triggers.',
          title: "Enable responsibility",
          actionButtonText:  "Enable",
          cancelButtonText: 'Cancel',
          action: action
        });
      } else {
        BS.confirmDialog.show({
          text: 'Disabling of the "${processBuildTriggersResp.displayName}" responsibility will remove "' + nodeId + '" node from the list of nodes processing build triggers.' +
                '<p><strong>Warning</strong>: new builds won\'t be triggered if no TeamCity nodes have the "${processBuildTriggersResp.displayName}" responsibility.</p>',
          title: "Disable responsibility",
          actionButtonText:  "Disable",
          cancelButtonText: 'Cancel',
          action: action
        });
      }
    } else if (responsibilityName == '${processUsersRequestsResp.name()}') {
      <c:set var="proxyConfigHelpUrl">${util:helpUrl('', 'Multinode+Setup', 'ProxyConfiguration', false)}</c:set>
      if (enabled) {
        BS.confirmDialog.show({
          text: 'After enabling the "${processUsersRequestsResp.displayName}" responsibility, "' + nodeId + '" node user interface will become editable and the node will participate in the load balancing of the user requests.' +
            '<p><strong>Note</strong>: load balancing of the user requests requires a properly configured <a href="${proxyConfigHelpUrl}" title="View help" target="_blank">proxy server</a>.</p>',
          title: "Enable responsibility",
          actionButtonText:  "Enable",
          cancelButtonText: 'Cancel',
          action: action
        });
      } else {
        var message = 'After disabling the "${processUsersRequestsResp.displayName}" responsibility, "' + nodeId + '" node user interface will become read-only and the node will be excluded from the load balancing of the user requests.';
        if (nodeId == '${currentNodeId}') {
          message = 'Important! After disabling the "${processUsersRequestsResp.displayName}" responsibility, the entire user interface of the current node <strong>will become read-only</strong>.' +
          '<p>To enable this responsibility again you will have to switch to a node where this responsibility is still enabled.</p>';
        }
        BS.confirmDialog.show({
          text: message,
          title: "Disable responsibility",
          actionButtonText:  "Disable",
          cancelButtonText: 'Cancel',
          action: action
        });
      }
    } else if (responsibilityName == '${mainServerResp.name()}') {
      if (enabled) {
        BS.confirmDialog.show({
          text: 'After enabling the "${mainServerResp.displayName}" responsibility, "' + nodeId +
            '" node will become the main node with all the responsibilities of the main node automatically enabled (processing of the queued builds, management of agents, etc)',
          title: "Enable responsibility",
          actionButtonText:  "Enable",
          cancelButtonText: 'Cancel',
          action: action
        });
      } else {
        alert('Main node responsibility can not be disabled.');
      }
    } else {
      action();
    }
  },

  removeNode: function(nodeId) {
    BS.confirm("Are you sure you want to remove the settings configured for the node with id \"" + nodeId + "\"", function () {
      BS.ajaxRequest(BS.ClusterAdmin.url, {
        parameters: '&nodeId=' + nodeId + "&actionName=removeNode",
        onComplete: function (transport) {
          $('nodesData').refresh();
        }
      });
    });
  }
};

$j(document).ready(
  BS.PeriodicalRefresh.start(5, function() {
    $('nodesData').refresh();
  })
);

</script>
<style type="text/css">
  table.nodeInfo {
    width: 100%;
    border: 0;
  }

  table.nodeInfo td {
    padding-bottom: 1em;
  }

  table.settings td {
    vertical-align: top;
    padding-left: 1em;
    padding-right: 1em;
  }

  table.settings th.name.nodeId {
    white-space: nowrap;
    width: 20%;
  }

  table.settings th.name.responsibilities, table.settings td.responsibilities {
    width: 30%;
    white-space: nowrap;
  }

  .icon.icon-check.disabledIcon,
  .icon.icon-check-empty.disabledIcon {
    color: #acaeb2;
  }

  .icon.icon-check {
    color: #1f2326;
  }

  span.error {
    white-space: pre-wrap;
    margin-left: 0;
  }

  .errorsContainer {
    min-height: 20px;
  }

  span.smallNote {
    margin-left: 0;
  }

  .projectsPopupConfig {
    margin-top: 3em;
  }

  .nodesConfig {
    margin-top: 1em;
  }

  h2 {
    border-bottom: none;
  }

  .responsibilityStats {
    margin-left: 16px;
  }

  .offline {
    color: #acaeb2;
  }
</style>

<bs:linkScript>
  /js/bs/blocks.js
  /js/bs/blocksWithHeader.js
</bs:linkScript>

<div>
  <c:set var="canChangeSettings" value="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}"/>

  <div class="nodesConfig">
  <h2>Available Nodes</h2>

  <bs:refreshable containerId="nodesData" pageUrl="${pageUrl}">
  <c:set var="numNodes" value="${fn:length(teamcityNodes)}"/>
  <div class="smallNote" style="margin-left: 0">There <bs:are_is val="${numNodes}"/> ${numNodes} node<bs:s val="${numNodes}"/> running. <bs:help file="Multinode+Setup"/></div>

  <c:if test="${not empty teamcityNodes}">

  <div class="errorsContainer"><span class="error"></span></div>

  <c:if test="${not empty missingResponsibilities}">
  <div class="attentionComment">
    <c:set var="missingNum" value="${fn:length(missingResponsibilities)}"/>
    <c:forEach items="${missingResponsibilities}" var="nr" varStatus="pos">
      <c:set var="separator"><c:if test="${not pos.last}"><c:if test="${missingNum - pos.index eq 2}">&nbsp;and </c:if><c:if test="${missingNum - pos.index gt 2}">, </c:if></c:if></c:set>
      <c:set var="nletter"><c:if test="${pos.first}">N</c:if><c:if test="${not pos.first}">n</c:if></c:set>
      <c:set var="qletter"><c:if test="${pos.first}">Q</c:if><c:if test="${not pos.first}">q</c:if></c:set>
      <c:choose>
        <c:when test="${nr == processBuildTriggersResp}">${nletter}ew builds won't be triggered${separator}</c:when>
        <c:when test="${nr == checkForChangesResp}">${qletter}ueued builds won't be able to start${separator}</c:when>
      </c:choose>
    </c:forEach>

    since no TeamCity nodes have the following responsibilities:
      <c:forEach items="${missingResponsibilities}" var="nr" varStatus="pos">
        "<c:out value="${nr.displayName}"/>"<c:if test="${not pos.last}"><c:if test="${missingNum - pos.index eq 2}">&nbsp;and </c:if><c:if test="${missingNum - pos.index gt 2}">, </c:if></c:if>
      </c:forEach>
  </div>
  </c:if>
  <table class="settings runnerFormTable">
  <tr>
    <th class="name nodeId">Node ID</th>
    <th class="name responsibilities">Node Responsibilities</th>
    <th class="name">Description</th>
  </tr>
  <c:forEach items="${teamcityNodes}" var="n" varStatus="pos">
    <c:set var="startTime">(offline)</c:set>
    <c:set var="nodeClass">offline</c:set>
    <c:if test="${n.online}">
      <c:set var="status" value="online"/>
      <c:if test="${n.stopping}"><c:set var="status" value="stopping"/></c:if>
      <c:set var="startTime">(${status}, start time: <bs:date value="${n.startTime}"/>, last activity: <bs:date value="${n.lastActivityTime}"/>)</c:set>
      <c:set var="nodeClass">online</c:set>
    </c:if>
    <tr>
      <td class="nodeId ${nodeClass}">
        <c:if test="${n.current}">
          <span title="Current server"><bs:svgIcon name="star-filled" className="actionIconMain starIcon"/></span>
        </c:if>
        <c:out value="${n.id}"/><br/>
        ${startTime}
      </td>
      <td class="responsibilities ${nodeClass}" data-node-id="${n.id}">

        <c:if test="${n.uneditableConfiguration}">
          <div class="messageNote" title="Node responsibilities are passed via command line or environment variable and cannot be edited" style="margin-top: 5px;">
            <c:if test="${not n.current}">
              Uneditable: enforced via command-line parameters
            </c:if>
            <c:if test="${n.current}">
              Responsibilities are enforced via command-line parameters<br>
              All manual changes will be reset on the server restart
            </c:if>
          </div>
        </c:if>

        <c:set var="supportedResps" value="${filteredSupportedResps.get(n.id)}"/>
        <c:set var="effectiveResps" value="${n.effectiveResponsibilities}"/>
        <c:if test="${empty supportedResps}"><em>&lt;read only node, responsibilities cannot be assigned&gt;</em></c:if>
        <c:forEach items="${supportedResps}" var="resp">
          <c:if test="${resp.canBeAssigned()}">
            <c:set var="canChangeResp" value="${canChangeSettings and (n.secondaryNode or (resp != processUsersRequestsResp and resp != mainServerResp and canEditMainNodeResps))}"/>
            <c:set var="uneditable" value="${n.uneditableConfiguration and not n.current}"/>
            <c:if test="${uneditable}">
              <!-- We cannot pass changed responsibility to uneditable node, it has fixed responsibilites which can only be changed directly on the node -->
              <c:set var="canChangeResp" value="${false}"/>
            </c:if>

            <c:set var="respEffective" value="${effectiveResps.contains(resp)}" />
            <c:set var="respEnabled" value="${n.responsibilityEnabled(resp)}" />
            <c:set var="switchControlId">switchControl_${resp.name()}_${n.id}</c:set>

            <c:choose>
              <c:when test="${respEnabled and canChangeResp}">
                <c:set var="onClick">BS.ClusterAdmin.setNodeResponsibilityEnabled('#${switchControlId}', '<bs:escapeForJs text="${n.id}"/>', '${resp.name()}', false)</c:set>
                <c:set var="statusCss">icon icon-check</c:set>
                <c:set var="title">This responsibility is enabled. Click to disable it.</c:set>
              </c:when>
              <c:when test="${respEnabled and not canChangeResp}">
                <c:set var="onClick"></c:set>
                <c:set var="statusCss">icon icon-check disabledIcon</c:set>
                <c:set var="title">This responsibility is enabled.</c:set>
              </c:when>
              <c:when test="${not respEnabled and not uneditable and (canChangeSettings or (resp == mainServerResp))}">
                <c:set var="onClick">BS.ClusterAdmin.setNodeResponsibilityEnabled('#${switchControlId}', '<bs:escapeForJs text="${n.id}"/>', '${resp.name()}', true)</c:set>
                <c:set var="statusCss">icon icon-check-empty</c:set>
                <c:set var="title">This responsibility is disabled. Click to enable it.</c:set>
              </c:when>
              <c:when test="${not respEnabled and not canChangeResp}">
                <c:set var="onClick"></c:set>
                <c:set var="statusCss">icon icon-check-empty disabledIcon</c:set>
                <c:set var="title">This responsibility is disabled.</c:set>
              </c:when>
            </c:choose>

            <c:set var="styleForMainNodeResp">${resp eq mainServerResp ? 'margin-bottom: 8px;' : ''}</c:set>
            <div style="${styleForMainNodeResp}">
              <c:set var="style">${empty onClick ? 'style="cursor:auto"' : 'style="cursor:pointer"'}</c:set>
              <span href="#" onclick="${onClick}; event.stopPropagation();" class="${statusCss}" title="${title}" ${style} id="${switchControlId}"></span>
              <forms:saving id="${switchControlId}_progress" style="margin-left: -2px"/>
              <span onclick="${onClick}; event.stopPropagation();" ${style} ><c:out value="${resp.displayName}"/></span>
              <div style="padding-left: 1.2em"> <%-- responsibility options--%>
                <c:set var="canChangeProperties" value="${canChangeSettings and not uneditable}"/>
                <c:choose>
                  <c:when test="${resp eq processBuildMessagesResp}">
                    <c:set var="percentageLimit" value="${n.getResponsibilityProperty(resp, 'percentageLimit')}"/>

                    Max percent of builds to process:
                    <c:if test="${empty percentageLimit}">&lt;auto&gt;</c:if>
                    <c:if test="${not empty percentageLimit}">${percentageLimit}%</c:if>
                    <c:if test="${canChangeProperties}">&nbsp;&nbsp;<a href="#" onclick="BS.ProcessBuildMessagesSettings.show('${n.id}', '${percentageLimit}'); return false;">Edit</a></c:if>

                  </c:when>
                  <c:when test="${resp eq processUsersRequestsResp and not empty n.getResponsibilityProperty(resp, usersRoutingGroupKeysPropName)}">
                    <c:set var="groupKeys" value="${n.getResponsibilityProperty(resp, usersRoutingGroupKeysPropName)}"/>
                    The users groups routed to this node:<br/><c:out value='${groupKeys.trim().replaceAll("[ ]+", ",").replaceAll("[,]+", ", ")}'/>
                  </c:when>
                </c:choose>
              </div>
              <div class="grayNote responsibilityStats">
                <c:choose>
                  <c:when test="${resp eq processBuildTriggersResp}">
                    <c:choose>
                      <c:when test="${respEnabled}">
                        This node is processing the build triggers.
                        <bs:trimWhitespace>
                          <span id="triggersInfoPopup" onmouseover="if(!window.event) window.event = event;BS.bindPopup(this, 'simplePopup', {show:[{shift: {x: 0, y: 20}}]});">
                            <span class="pc__label"><a href="#" class="popupLink" onclick="return false"> View triggers assigned to each node.</a></span><span
                              class="pc__toggle-wrapper">&nbsp;<span class="icon icon16 toggle"></span></span></span>
                                  <%@ include file="triggersPopup.jspf" %>
                        </bs:trimWhitespace>
                      </c:when>
                      <c:when test="${respEffective}">
                        Some build triggers related tasks are still in progress on this node
                      </c:when>
                    </c:choose>
                  </c:when>
                  <c:when test="${resp eq processBuildMessagesResp}">
                    <c:set var="nodeBuildStats" value="${buildsStats[n.id]}"/>
                    <c:if test="${(not empty nodeBuildStats and nodeBuildStats.assignedRunningBuilds gt 0) or respEnabled}">
                      Running builds assigned to this node: <strong>${nodeBuildStats.assignedRunningBuilds}</strong> of <strong>${totalRunning}</strong>
                    </c:if>
                  </c:when>
                  <c:when test="${resp eq mainServerResp}">
                    <c:if test="${respEffective}">
                      This node is responsible for starting new builds, management of agents, etc
                    </c:if>
                    <c:if test="${not respEffective and respEnabled}">
                      Trying to obtain an exclusive lock on the TeamCity database
                    </c:if>
                  </c:when>
                  <c:when test="${resp eq checkForChangesResp}">
                    <c:set var="nodePollingStats" value="${vcsPollingStats[n.id]}"/>
                    <c:if test="${not empty nodePollingStats}">
                      <c:choose>
                        <c:when test="${not respEnabled and respEffective}">
                          Some VCS repositories polling tasks are still in progress on this node
                        </c:when>
                        <c:when test="${respEffective}">
                          <c:if test="${nodePollingStats.pollingStarted}">VCS repositories polling is in progress<br/></c:if>
                          <c:if test="${nodePollingStats.lastHourTasksNum gt 0}">
                            Commit hooks and builds changes collecting tasks (within last hour): <strong>${nodePollingStats.lastHourTasksNum}</strong>
                          </c:if>
                        </c:when>
                      </c:choose>
                    </c:if>
                  </c:when>
                </c:choose>
              </div>
            </div>
          </c:if>
        </c:forEach>
      </td>
      <td class="${nodeClass}">
        <c:if test="${not n.online}">
          <span style="float: right">
            <button class="btn btn_mini" onclick="BS.ClusterAdmin.removeNode('${n.id}'); return false;">Remove</button>
          </span>
        </c:if>
        URL: <a href="<c:out value="${n.url}"/>" target="_blank" rel="noreferrer" onclick="event.stopPropagation();" class="nodeUrl"><c:out value="${n.url}"/></a>
        <br/>
        <c:out value="${n.description}"/>

        <c:if test="${n.current && not empty nodeResponsibilitiesConfigDescription }">
          <br>
          <span style="word-break: break-all;">
            Responsibilities are passed via
            <c:out value="${nodeResponsibilitiesConfigDescription}"/>
          </span>
        </c:if>

      </td>
    </tr>
  </c:forEach>
  </table>
  </c:if>
  </bs:refreshable>
  </div>

  <div class="projectsPopupConfig">
    <h2>Cross-Server Projects Popup</h2>
    <div class="smallNote" style="margin-left: 0">TeamCity projects popup can be configured to list projects from different TeamCity servers. <bs:help file="Configuring+Cross-Server+Projects+Popup"/></div>

    <c:choose>
      <c:when test="${canChangeSettings}">
        <div id="linkedServers" />
        <script>
          ReactUI.renderEditFederation(document.getElementById('linkedServers'));
        </script>
      </c:when>
      <c:otherwise>
        <table class="settings runnerFormTable" id="linkedServersTableReadOnly">
          <tr>
            <th class="name nodeUrl">TeamCity servers</th>
          </tr>
          <tr id="linkedServersReadOnly">
            <td>
              Loading...
            </td>
          </tr>
        </table>
        <script type="text/javascript">
          $j.getJSON(base_uri  + '/app/rest/ui/federation/servers')
            .fail(function() {
              BS.Log.error('An error occurred in attempt to load servers list from /app/rest/ui/federation/servers');
            })
            .then(servers => {
              $j('#linkedServersReadOnly').html('');
              if(servers.length > 0) {
                servers.forEach(function (server) {
                  $j('#linkedServersTableReadOnly').append("<tr><td><a href='" + server.url + "'>" + server.url + "</a></td></tr>");
                });
              }
              else {
                $j('#linkedServersTableReadOnly').append("<tr><td>TeamCity servers are not configured</td></tr>");
              }
            });
        </script>
      </c:otherwise>
    </c:choose>
  </div>

</div>

  <bs:modalDialog formId="processBuildMessagesSettings" title="" action="#"
                closeCommand="BS.ProcessBuildMessagesSettings.close()"
                saveCommand="BS.ProcessBuildMessagesSettings.save()">
    <input type="hidden" name="actionName" value="setResponsibilityProperty"/>
    <input type="hidden" name="nodeResponsibility" value="${processBuildMessagesResp}"/>
    <input type="hidden" id="processBuildMessagesSettings_nodeId" name="nodeId" value=""/>
    <table class="runnerFormTable">
      <tr>
        <th><label for="percentageLimitInput">Percentage limit:</label></th>
        <td>
          <input id="percentageLimitInput" name="property_percentageLimit" type="text" value="" class="smallField" maxlength="3">
          <span class="error" id="percentageLimit_error"></span>
          <span class="smallNote">Maximum % of running builds that can be assigned to this node.<br/>
            If empty, the decision will be made automatically.
          </span>
        </td>
      </tr>
    </table>
    <span class="error" id="processBuildMessagesSettings_error"></span>
    <div class="popupSaveButtonsBlock">
      <forms:submit label="Save"/>
      <forms:cancel showdiscardchangesmessage="false" onclick="BS.ProcessBuildMessagesSettings.close();" />
    </div>
  </bs:modalDialog>

