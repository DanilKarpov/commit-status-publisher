<%@ page import="jetbrains.buildServer.DevelopmentMode" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="bundledPlugins" type="java.util.Collection<jetbrains.buildServer.web.plugins.web.PluginModelBean>" scope="request"/>
<jsp:useBean id="unbundledPlugins" type="java.util.Collection<jetbrains.buildServer.web.plugins.web.PluginModelBean>" scope="request"/>
<jsp:useBean id="modifiedPlugins" type="java.util.Collection<jetbrains.buildServer.web.plugins.web.PluginModelBean>" scope="request"/>
<jsp:useBean id="updatedPlugins" type="java.util.Collection<jetbrains.buildServer.web.plugins.web.PluginModelBean>" scope="request"/>
<%--@elvariable id="loadablePlugins" type="java.util.Collection<jetbrains.buildServer.web.plugins.web.PluginModelBean>"--%>
<%--@elvariable id="reloadablePlugins" type="java.util.Collection<jetbrains.buildServer.web.plugins.web.PluginModelBean>"--%>
<%--@elvariable id="appliedAfterRestart" type="java.util.Collection<jetbrains.buildServer.web.plugins.web.PluginModelBean>"--%>
<%--@elvariable id="loadablePluginsJson" type="java.lang.String"--%>
<%--@elvariable id="reloadablePluginsJson" type="java.lang.String"--%>
<%--@elvariable id="restartSupported" type="java.lang.Boolean"--%>
<%--@elvariable id="editAllowedForNode" type="java.lang.Boolean"--%>

<bs:linkScript>
  /js/bs/hostnameConfirm.js
  /js/bs/serverRestart.js
</bs:linkScript>

<%
  request.setAttribute("developmentMode", DevelopmentMode.isEnabled);
%>

<div id="pluginsList" class="plugins">
  <c:if test="${intprop:getBoolean('teamcity.plugins.uiControls.enableDisableAll')}">
  <span style="float: right;">
  <div>
  <a href="#" onclick="BS.Plugins.toggleEnabledStatus('___ALL_DISABLE___', 'all reloadable', null, false)" title="Disable plugin">Disable all reloadable plugins</a>
  </div>
  <div>
  <a href="#" onclick="BS.Plugins.toggleEnabledStatus('___ALL_ENABLE___', 'all reloadable', null, true)" title="Disable plugin">Enable all reloadable plugins</a>
  </div>
  </span>
  </c:if>

  <div>
    This TeamCity installation has <strong>${fn:length(bundledPlugins) + fn:length(unbundledPlugins)}</strong>
    plugins<c:if test="${not empty unbundledPlugins}"> (including ${fn:length(unbundledPlugins)} external)</c:if><c:if test="${not empty updatedPlugins}">,
    ${fn:length(updatedPlugins)} updates</c:if>
    <c:if test="${not pluginsIntegration}">
      <br/>
      <a href="<c:out value="${pluginsRepositoryUrl}/teamcity"/>" target="_blank" rel="noreferrer">Available plugins</a>
    </c:if>
  </div>

  <c:if test="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS') and editAllowedForNode}">
    <div id="uploadPluginButton">
      <c:choose>
        <c:when test="${intprop:getBooleanOrTrue('teamcity.plugins.uiControls.enabled')}">
          <c:if test="${pluginsIntegration}">
            <c:url var="action" value="${pluginsRepositoryUrl}/teamcity/server"/>
            <form id="openPluginsForm" method="post" action="${action}">
              <input type="hidden" name="url" value="<c:out value="${serverUrl}"/>"/>
              <input type="hidden" name="build" value="${serverBuild}"/>
              <input type="hidden" name="mode" value="${serverMode}"/>
              <input type="hidden" name="uuid" value="${serverUuid}"/>
            </form>
            <forms:button onclick="return BS.Plugins.openPluginsRepository();">Browse plugins repository</forms:button>
            <div class="shift"></div>
          </c:if>
          <forms:addButton onclick="return BS.Plugins.UploadPluginDialog.open();">Upload plugin zip</forms:addButton>
        </c:when>
        <c:otherwise>
          <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Plugins management actions are disabled using internal property 'teamcity.plugins.uiControls.enabled = false'.
        </c:otherwise>
      </c:choose>
    </div>
    <c:if test="${pluginsIntegration}">
      <div>
        <forms:checkbox name="checkPluginUpdates" onclick="BS.Plugins.toggleCheckUpdates(this.checked);" checked="${checkPluginUpdates}"/>
        <label for="checkPluginUpdates">Periodically check for plugin updates</label>
        <input type="button" value="Check Now" class="btn btn_mini" onclick="BS.Plugins.checkUpdates();">
      </div>
    </c:if>
  </c:if>

  <c:if test="${fn:length(loadablePlugins) > 0}">
    <forms:attentionComment>
      Uploaded <bs:plural txt="plugin" val="${fn:length(loadablePlugins)}"/>:
      <c:forEach items="${loadablePlugins}" var="plugin" varStatus="status">
        <a href="#" onclick="BS.Plugins.focus('${util:forJSIdentifier(plugin.pluginRoot)}')"><c:out value="${plugin.name}"/></a><c:if test="${!status.last}">, </c:if>
      </c:forEach>

      <div style="margin-top: 1em;"><a href="#" class="btn btn_mini" id="loadAllPlugins">Enable uploaded plugins</a></div>
    </forms:attentionComment>
  </c:if>
  <c:if test="${fn:length(reloadablePlugins) > 0}">
    <forms:attentionComment>
      Updated <bs:plural txt="plugin" val="${fn:length(reloadablePlugins)}"/>:
      <c:forEach items="${reloadablePlugins}" var="plugin" varStatus="status">
        <a href="#" onclick="BS.Plugins.focus('${util:forJSIdentifier(plugin.pluginRoot)}')"><c:out value="${plugin.name}"/></a><c:if test="${!status.last}">, </c:if>
      </c:forEach>
      <div style="margin-top: 1em">
        <div style="margin-top: 1em; display: inline">
          <c:choose><c:when test="${restartSupported}">
            <a href="#" class="btn btn_mini" id="pluginsRestartServer">Restart server</a>
          </c:when><c:otherwise>Restart server manually</c:otherwise></c:choose><c:if
            test="${not empty loadablePlugins}"> (this will also load the newly uploaded plugins).</c:if>
        </div>
        or
        <div style="margin-top: 1em; display: inline"><a href="#" class="btn btn_mini" id="reloadAllPlugins">Reload plugins without restart (experimental)</a></div>
      </div>
    </forms:attentionComment>
  </c:if>
  <c:if test="${fn:length(appliedAfterRestart) > 0}">
    <forms:attentionComment>
      ${fn:length(appliedAfterRestart)} modified <bs:plural txt="plugin" val="${fn:length(appliedAfterRestart)}"/>:
      <c:forEach items="${appliedAfterRestart}" var="plugin" varStatus="status">
        <a href="#" onclick="BS.Plugins.focus('${util:forJSIdentifier(plugin.pluginRoot)}')"><c:out value="${plugin.name}"/></a><c:if test="${!status.last}">, </c:if>
      </c:forEach>
      <div style="margin-top: 1em;">
        <c:choose><c:when test="${restartSupported}">
          <a href="#" class="btn btn_mini" id="pluginsRestartServer">Restart server</a>
        </c:when><c:otherwise>Restart server manually</c:otherwise></c:choose><c:if
          test="${not empty loadablePlugins}"> (this will also load the newly uploaded plugins).</c:if>
      </div>
    </forms:attentionComment>
  </c:if>

  <table class="parametersTable">
    <c:if test="${not empty updatedPlugins}">
      <c:set var="title"><h2 class="noBorder" style="margin-left: -0.8em">Available updates</h2></c:set>
      <c:set var="plugins" value="${updatedPlugins}"/>
      <c:set var="pluginsType" value="updated"/>
      <c:set var="deleteAllowed" value="${true && intprop:getBooleanOrTrue('teamcity.plugins.uiControls.enabled')}"/>
      <%@ include file="_pluginsTable.jspf" %>
    </c:if>

    <c:if test="${not empty unbundledPlugins}">
      <c:set var="title"><h2 class="noBorder" style="margin-left: -0.8em">External plugins</h2></c:set>
      <c:set var="plugins" value="${unbundledPlugins}"/>
      <c:set var="pluginsType" value="unbundled"/>
      <c:set var="deleteAllowed" value="${true && intprop:getBooleanOrTrue('teamcity.plugins.uiControls.enabled')}"/>
      <%@ include file="_pluginsTable.jspf" %>
    </c:if>

    <c:set var="title"><h2 class="noBorder" style="margin-left: -0.8em">Bundled plugins</h2></c:set>
    <c:set var="plugins" value="${bundledPlugins}"/>
    <c:set var="pluginsType" value="bundled"/>
    <c:set var="deleteAllowed" value="${false}"/>
    <%@ include file="_pluginsTable.jspf" %>
  </table>
</div>

<c:url var="action" value="/admin/pluginUpload.html"/>
<bs:dialog dialogId="uploadPluginDialog" title="Upload plugin zip" closeCommand="BS.Plugins.UploadPluginDialog.close()" dialogClass="uploadDialog">
  <forms:multipartForm id="uploadPLuginForm" action="${action}" targetIframe="hidden-iframe" onsubmit="return BS.Plugins.UploadPluginDialog.validate();">
    <input type="text" id="fileName" name="fileName" value="" class="mediumField" style="display:none;"/>
    <table class="runnerFormTable">
      <tr>
        <th>Plugin</th>
        <td>
          <forms:file name="fileToUpload"/>
          <div id="uploadError" class="error hidden"></div>
        </td>
      </tr>
    </table>
    <div id="overwriteWarning" class="attentionComment" style="display: none;">
      The plugin with the same filename already exists and will be overwritten by the uploaded file. Proceed?
    </div>
    <div class="popupSaveButtonsBlock">
      <forms:submit id="uploadPLuginDialogSubmit" label="Upload plugin zip"/>
      <forms:cancel onclick="BS.Plugins.UploadPluginDialog.close()"/>
      <forms:saving id="uploadingProgress" savingTitle="Uploading..."/>
    </div>
  </forms:multipartForm>
</bs:dialog>

<c:url var="action" value="/admin/plugins.html"/>
<bs:dialog dialogId="installPluginDialog" title="Install plugin from the JetBrains Plugins Repository" closeCommand="BS.Plugins.InstallPluginDialog.close()" dialogClass="installDialog">
  <table class="runnerFormTable" id="installPluginInfo" style="display: none;">
    <tr>
      <th>Name</th>
      <td id="installPluginName"><c:out value="${installPluginId}"></c:out></td>
    </tr>
    <tr id="installPluginDescription" style="display: none;">
      <th>Description</th>
      <td></td>
    </tr>
    <tr>
      <th>Version</th>
      <td id="installPluginVersion"><c:out value="${installPluginUpdateId}"></c:out></td>
    </tr>
    <tr id="installPluginVendor" style="display: none;">
      <th>Vendor</th>
      <td></td>
    </tr>
  </table>
  <div id="installPluginWarning" class="attentionComment" style="display: none;">
    <c:out value="${installPluginWarning}"></c:out>
  </div>
  <div id="installPluginError" class="attentionComment attentionRed" style="display: none;">
    <bs:buildStatusIcon type="red-sign"/>
    <span class="jsErrorText"><c:out value="${installPluginError}"></c:out></span>
  </div>
  <div class="popupSaveButtonsBlock">
    <forms:submit id="installPluginDialogSubmit" label="Install"
                  onclick="BS.Plugins.InstallPluginDialog.install()" />
    <forms:cancel onclick="BS.Plugins.InstallPluginDialog.close()"/>
    <forms:progressRing id="installingProgress" style="display: none" progressTitle="Installing..."/>
    <forms:progressRing id="pluginInfoProgress" progressTitle="Loading info..."/>
  </div>
</bs:dialog>

<script type="text/javascript">
  BS.Plugins.UploadPluginDialog.prepareFileUpload();
  <c:forEach items="${unbundledPlugins}" var="unbundledPlugin">
  BS.Plugins.addOverwriteCandidate('${util:forJS(unbundledPlugin.originalPluginRoot, true, false)}');
  BS.Plugins.registerPlugin('${util:forJS(unbundledPlugin.pluginName, true, false)}', '${util:forJS(unbundledPlugin.pluginRoot, true, false)}', ${unbundledPlugin.latestVersion},
    '${util:forJS(unbundledPlugin.version, true, false)}', '${util:forJS(unbundledPlugin.UUID, true, false)}');
  </c:forEach>
  <c:forEach items="${bundledPlugins}" var="bundledPlugin">
  BS.Plugins.registerPlugin('${util:forJS(bundledPlugin.pluginName, true, false)}', '${util:forJS(bundledPlugin.pluginRoot, true, false)}', ${bundledPlugin.latestVersion},
    '${util:forJS(bundledPlugin.version, true, false)}', '${util:forJS(bundledPlugin.UUID, true, false)}');
  </c:forEach>

  <c:if test="${pluginsIntegration and not empty installPluginId and not empty installPluginUpdateId}">
  BS.Plugins.InstallPluginDialog.open("${util:forJS(installPluginId, true, false)}", "${util:forJS(installPluginUpdateId, true, false)}");
  </c:if>

  $j(function() {
    $j('#loadAllPlugins').on('click', function() {
      BS.Plugins.loadAllPlugins(${loadablePluginsJson});
    });
    $j('#reloadAllPlugins').on('click', function() {
      BS.Plugins.reloadAllPlugins(${reloadablePluginsJson});
    });
    $j('#pluginsRestartServer').on('click', function() {
      BS.ServerRestarter.restartServer();
    });
  });
</script>

