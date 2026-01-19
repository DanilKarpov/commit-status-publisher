<%@ page import="jetbrains.buildServer.serverSide.crypt.RSACipher" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnections" type="java.util.Map" scope="request"/>
<jsp:useBean id="supportedProviders" type="java.util.Map" scope="request"/>

<c:url var="oauthConnectionsUrl" value="/admin/oauth/connections.html"/>
<c:set var="rootUrl" value="${WebUtil.getRootUrl(pageContext.request)}"/>
<c:set var="afterAddUrl" value="${param['afterAddUrl']}"/>

<style type="text/css">

.error {
  word-break: break-all;
}

.serviceSettings, .gitHubUrl {
  display: none;
}

#OAuthConnectionDialog {
  width: 45em;
}

table.runnerFormTable td:first-child {
  width: 10em;
}

table.runnerFormTable label {
  width: 10em;
}

table.runnerFormTable input[type='text'] {
  width: 20em;
}

table.runnerFormTable td {
  vertical-align: top;
}
</style>
<script type="text/javascript">
  BS.OAuthConnectionDialog = OO.extend(BS.PluginPropertiesForm, OO.extend(BS.AbstractModalDialog, {
    getContainer: function() {
      return $('OAuthConnectionDialog');
    },

    formElement: function() {
      return $('OAuthConnection');
    },

    savingIndicator: function() {
      return $('saveProgress');
    },

    showAddDialog: function(type) {
      this.enable();
      $j('#OAuthConnectionTitle').text('Add Connection');
      $j('#connectionType').show();
      $j("#editConnectionAdditionalButtons").empty();
      $j('#readOnlyConnectionType').hide();
      this.formElement().connectionId.value = '';
      this.formElement().afterAddUrl.value = '<bs:escapeForJs text="${afterAddUrl}"/>';
      $('typeSelector').setSelectValue(type == null ? '' : decodeURIComponent(type));
      this.providerChanged($('typeSelector'));
      this.showCentered();
    },

    showEditDialog: function (event, connId, providerDisplayName, readOnly) {
      if (event) {
        const target = event.target;
        if (target.nodeName === 'SPAN') {
          return;
        }
        if (target.nodeName === 'A' && !target.parentElement.classList.contains('edit')) {
          return;
        }
      }

      this.enable();
      $j('#OAuthConnectionTitle').text('Edit Connection');
      $j('#connectionType').hide();
      $j("#editConnectionAdditionalButtons").empty();
      $j('#readOnlyConnectionType').show();
      $j('#readOnlyConnectionType').text(providerDisplayName);
      this.formElement().providerType.value = '';
      this.formElement().connectionId.value = connId;
      this.loadParameters(readOnly);
      this.showCentered();

    },

    providerChanged: function(selector) {
      this.formElement().providerType.value = '';
      $j('#connectionParams').html('');
      if (selector.selectedIndex > 0) {
        this.formElement().providerType.value = selector.options[selector.selectedIndex].value;
        this.loadParameters();
      }
      $j("#editConnectionAdditionalButtons").empty();
    },

    loadParameters: function(readOnly) {
      $('parametersProgress').show();
      var that = this;
      BS.ajaxUpdater('connectionParams', window['base_uri'] + '/admin/oauth/showConnection.html', {
        parameters: 'providerType=' + this.formElement().providerType.value + "&projectId=" + this.formElement().projectId.value + "&connectionId=" + this.formElement().connectionId.value,
        evalScripts: true,
        onComplete: function () {
          $('parametersProgress').hide();

          if (readOnly) {
            that.disable();
          }
          that.recenterDialog();
        }
      });
    },

    save: function() {
      if (this.formElement().connectionId.value == '' && $('typeSelector').selectedIndex <= 0) {
        alert("Please select a type of OAuth connection");
        return false;
      }

      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function(form, responseXML, err) {
          const createdVcsConnectionFromAdminPageEvent = 'VCS_CONNECTION_CREATED';
          err = BS.XMLResponse.processErrors(responseXML, {}, BS.PluginPropertiesForm.propertiesErrorsHandler);

          form.setSaving(false);
          if (err) {
            form.enable();
          } else {
            if (!BS.XMLResponse.processRedirect(responseXML)) {
              $('connectionsTable').refresh();
              BS.OAuthConnectionDialog.close();
              /*
              * TODO: Temporary solution to handle the case when the user clicks on the "Add connection" button
              * Task: TW-93452 Improve VCS selection on the create Pipeline page, and provide a convenient way to add extra VCS connections.
              */
              if (window['selectedVcsProvider']) {
                const locationSearch = location.search;
                const openerLocationSearch = window.opener ? window.opener.location.search : '';
                const projectId = new URLSearchParams(locationSearch).get('projectId');
                const isOpenerEditPage = new URLSearchParams(openerLocationSearch).get('edit') !== null;

                if (isOpenerEditPage) {
                  window.opener.postMessage(JSON.stringify({
                    event: createdVcsConnectionFromAdminPageEvent,
                    type: window['selectedVcsProvider'],
                  }));
                  window.close();
                } else if (projectId) {
                  location.href =  window['base_uri'] + '/pipelines/create?projectId=' + projectId;
                }
              }
              /*
              * End of temporary solution.
              */
            }
          }
        }
      }));
      return false;
    }
  }));

  BS.OAuth = {
    deleteConnection: function(connectionId) {
      BS.confirm("Are you sure you want to delete this OAuth connection?", function () {
        BS.ajaxRequest('${oauthConnectionsUrl}', {
          parameters: 'deleteConnection=' + connectionId + "&projectId=${currentProject.externalId}",

          onComplete: function() {
            $('connectionsTable').refresh();
          }
        });
      })
    }
  };

  BS.OAuthCapabilitiesLoader = {
    load: function (element) {
      const connectionId = element.dataset.connectionId;
      const url = '${rootUrl}' + element.dataset.capUrl;
      const waiter = $('capabilitiesWaiter_' + connectionId);
      waiter.show();
      BS.ajaxUpdater(element, url, {
        evalScripts: true,
        parameters: {
          'projectId': '${currentProject.externalId}',
          'connectionId': connectionId
        }
      });
    }
  };

  BS.Clipboard('.clipboard-btn');
</script>
<div class="section noMargin">
  <h2 class="noBorder">Connections</h2>
  <bs:smallNote>Supported types of connections: <c:forEach items="${supportedProviders}" var="pt" varStatus="pos"><c:out value="${pt.value.displayName}"/><c:if test="${not pos.last}">, </c:if></c:forEach>.</bs:smallNote>

  <bs:refreshable containerId="connectionsTable" pageUrl="${pageUrl}">

    <bs:messages key="connectionAdded"/>
    <bs:messages key="connectionUpdated"/>
    <bs:messages key="connectionRemoved"/>
    <bs:messages key="thirdPartyInfo"/>

    <c:set var="canEdit" value="${afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT')}"/>
    <c:if test="${not currentProject.readOnly and canEdit}">
    <div>
      <forms:addButton onclick="BS.OAuthConnectionDialog.showAddDialog()">Add Connection</forms:addButton>
    </div>
    </c:if>

    <script type="text/javascript">
      var connectionsProviders = {};
    </script>

    <c:if test="${not empty oauthConnections}">
    <c:forEach items="${oauthConnections}" var="entry">
      <c:set var="project" value="${entry.key}"/>
      <c:set var="projectConnections" value="${entry.value}"/>
      <c:set var="inherited" value="${project != currentProject}"/>

      <c:if test="${inherited}">
        <br/>
        <p>Connections inherited from <admin:editProjectLink projectId="${project.externalId}"><c:out value="${project.name}"/></admin:editProjectLink>:</p>
      </c:if>
      <l:tableWithHighlighting className="parametersTable" highlightImmediately="true">
        <tr>
          <th style="width: 30%">Connection</th>
          <th colspan="${inherited or not canEdit ? 1 : currentProject.readOnly ? 3 : 4}">Parameters Description</th>
        </tr>
      <c:forEach items="${projectConnections}" var="con">
        <%--@elvariable id="con" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor"--%>
        <c:set var="connectionIdSafeAttribute" value="${util:forJS(con.id, true, true)}"/>
        <c:set var="connectionIdSafeValue" value="${util:forJS(con.id, true, false)}"/>
        <script type="text/javascript">
          connectionsProviders['${connectionIdSafeValue}'] = '<bs:forJs>${con.oauthProvider.displayName}</bs:forJs>';
        </script>
        <c:choose>
          <c:when test="${inherited}">
            <tr>
              <td>
                <c:if test="${con.connectionDisplayName != con.oauthProvider.displayName}"><em>(<c:out value='${con.oauthProvider.displayName}'/>)</em> </c:if><c:out value='${con.connectionDisplayName}'/>
                <br/>
                <bs:smallNote>
                  Connection ID: <span id="con_id_${connectionIdSafeAttribute}"><bs:out value="${connectionIdSafeAttribute}"/></span>
                  <span class="clipboard-btn tc-icon icon16 tc-icon_copy" data-clipboard-action="copy" data-clipboard-target="#con_id_${connectionIdSafeAttribute}"/>
                </bs:smallNote>
              </td>
              <td><bs:out value='${con.descriptionForUI}'/> ${con.additionalDescription}</td>
            </tr>
          </c:when>
          <c:otherwise>
            <c:set var="onclick" value="BS.OAuthConnectionDialog.showEditDialog(event, '${connectionIdSafeAttribute}', '${con.oauthProvider.displayName}', ${currentProject.readOnly})"/>
            <tr>
              <td class="highlight" onclick="${canEdit && not con.transientConnection ? onclick : ''}">
                <c:if test="${con.connectionDisplayName != con.oauthProvider.displayName}"><em>(<c:out value='${con.oauthProvider.displayName}'/>)</em> </c:if><c:out value='${con.connectionDisplayName}'/>
                <br/>
                <bs:smallNote>
                  Connection ID: <span id="con_id_${connectionIdSafeAttribute}"><bs:out value="${connectionIdSafeValue}"/></span>
                  <span class="clipboard-btn tc-icon icon16 tc-icon_copy" data-clipboard-action="copy" data-clipboard-target="#con_id_${connectionIdSafeAttribute}"/>
                </bs:smallNote>
              </td>
              <td class="highlight beforeActions" onclick="${canEdit && not con.transientConnection ? onclick : ''}">
                <c:if test="${con.oauthProvider.capabilitiesSupported and con.oauthProvider.isCapabilitiesEnabledForProject(currentProject)}">
                  <div id="capabilities_${connectionIdSafeAttribute}" class="capabilities" data-connection-id="${connectionIdSafeAttribute}" data-cap-url="${con.oauthProvider.capabilitiesUrl}">
                    <forms:saving id="capabilitiesWaiter_${connectionIdSafeAttribute}" style="float: none;"/>
                    <script type="text/javascript">
                      (function () {
                        BS.OAuthCapabilitiesLoader.load($('capabilities_${connectionIdSafeValue}'));
                      })();
                    </script>
                  </div>
                </c:if>
                <bs:out value='${con.descriptionForUI}'/> ${con.additionalDescription}
              </td>
              <c:if test="${not inherited and canEdit}">
                <td class="edit highlight capability-action">
                    <%-- filled in dynamically --%>
                </td>
                <td class="edit highlight" onclick="${onclick}">
                  <c:if test="${not con.transientConnection}">
                    <a href="#">${currentProject.readOnly || con.transientConnection ? 'View' : 'Edit'}</a>
                  </c:if>
                </td>
              <c:if test="${not currentProject.readOnly}">
                <td class="edit highlight">
                  <c:if test="${not con.transientConnection}">
                    <a href="#" onclick="BS.OAuth.deleteConnection('${connectionIdSafeAttribute}'); return false;">Delete</a>
                  </c:if>
                </td>
              </c:if>
              </c:if>
            </tr>
          </c:otherwise>
        </c:choose>
      </c:forEach>
      </l:tableWithHighlighting>
    </c:forEach>
    </c:if>
  </bs:refreshable>

  <bs:modalDialog formId="OAuthConnection" title="Add Connection" saveCommand="BS.OAuthConnectionDialog.save()" closeCommand="BS.OAuthConnectionDialog.close()" action="${oauthConnectionsUrl}">
    <table class="runnerFormTable" style="width: 99%;">
      <tr>
        <th>
          <label>Connection type: </label>
        </th>
        <td>
          <span id="connectionType">
            <forms:select name="typeSelector" enableFilter="true" onchange="BS.OAuthConnectionDialog.providerChanged(this)" className="longField">
              <option value="">-- Select a connection type --</option>
              <c:forEach items="${supportedProviders}" var="sp">
                <option value="${sp.key}"><c:out value="${sp.value.displayName}"/></option>
              </c:forEach>
            </forms:select>
            <forms:saving id="parametersProgress" className="progressRingInline"/>
          </span>
          <span id="readOnlyConnectionType"></span>
        </td>
      </tr>
    </table>

    <div id="connectionParams"></div>

    <span class="error" id="error_providerType"></span>

    <div class="popupSaveButtonsBlock">
      <forms:submit label="Save"/>
      <span id="editConnectionAdditionalButtons"></span>
      <forms:cancel onclick="BS.OAuthConnectionDialog.close()"/>
      <forms:saving id="saveProgress"/>
      <input type="hidden" name="projectId" value="${currentProject.externalId}"/>
      <input type="hidden" name="providerType" value=""/>
      <input type="hidden" name="connectionId" value=""/>
      <input type="hidden" name="afterAddUrl" value=""/>
      <input type="hidden" name="saveConnection" value="save"/>
      <input type="hidden" name="publicKey" id="publicKey" value="<c:out value='<%=RSACipher.getHexEncodedPublicKey()%>'/>"/>
    </div>
  </bs:modalDialog>
</div>
<script type="text/javascript">
  $j(document).ready(function() {
    /*
    * TODO: Temporary solution to handle the case when the user clicks on the "Add connection" button
    * Task: TW-93452 Improve VCS selection on the create Pipeline page, and provide a convenient way to add extra VCS connections.
    */
    var urlParams = new URLSearchParams(window.location.search);
    var selectedVcsProvider = urlParams.get('selectedVcsProvider');

    if (selectedVcsProvider) {
      const allowedValues = ['', 'GitLabCom', 'GitHub', 'BitBucketCloud'];
      const selectElement = document.getElementById('typeSelector');

      if (selectElement) {
        const options = selectElement.options ?? [];

        for (let i = options.length - 1; i >= 0; i--) {
          const option = options[i];
          if (!allowedValues.includes(option.value)) {
            selectElement.removeChild(option);
          }
        }
      }

      BS.OAuthConnectionDialog.showAddDialog(selectedVcsProvider);

      window['selectedVcsProvider'] = selectedVcsProvider;

      setTimeout(function() {
        var selector = $('typeSelector');
        if (selector) {
          selector.setSelectValue(selectedVcsProvider);
          BS.OAuthConnectionDialog.providerChanged(selector);
        }
      }, 100);

      urlParams.delete('selectedVcsProvider');
      var newUrl = window.location.pathname;

      if (urlParams.toString()) {
        newUrl += '?' + urlParams.toString();
      }

      window.history.replaceState({}, document.title, newUrl);

      return;
    }
    /*
    * End of temporary solution.
    */

    var parsedHash = BS.Util.paramsFromHash('&');
    var type = parsedHash['addDialog'];
    if (type) {
      BS.OAuthConnectionDialog.showAddDialog(type);
      document.location.hash = "";
    }
    else {
      var connectionId = parsedHash['editConnection'];
      if (connectionId) {
        BS.OAuthConnectionDialog.showEditDialog(null, connectionId, connectionsProviders[connectionId], false);
      }
    }
  })
</script>
