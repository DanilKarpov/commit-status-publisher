<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<jsp:useBean id="newVersionBeans" scope="request" type="java.util.Collection"/>
<jsp:useBean id="securityPatchesMode" scope="request" type="java.lang.String"/>
<jsp:useBean id="pendingSecurityPatches" scope="request" type="java.util.Collection"/>
<jsp:useBean id="canDownloadPluginUpdate" scope="request" type="java.lang.Boolean"/>

<bs:linkScript>
  /js/bs/hostnameConfirm.js
  /js/bs/serverRestart.js
  /js/bs/serverUpdate.js
  /js/bs/blocks.js
  /js/bs/blocksWithHeader.js
</bs:linkScript>
<bs:linkCSS>
  /css/admin/plugins.css
  /css/admin/serverUpdate.css
</bs:linkCSS>

<c:if test="${notSupportedReason != null}">
  <p>
    <forms:attentionComment>Auto update is turned off: <c:out value="${notSupportedReason}"/><bs:help file="Upgrade" anchor="UpgradingTeamCityServer"/></forms:attentionComment>
  </p>
</c:if>

<div id="checkForUpdate">
  <forms:button id="checkForUpdatesBtn" onclick="BS.TeamCityUpdater.checkForUpdates(); return false;">Check for updates</forms:button>
  <forms:saving id="checkForUpdatesProgress" className="progressRingInline" savingTitle="Checking for updates..."/>
</div>

<bs:refreshable containerId="updateOptionsList" pageUrl="${pageUrl}">
  <c:if test="${lastCheckDate != null}">
    <bs:smallNote>Last check: <bs:date value="${lastCheckDate}" smart="true" no_smart_title="true"/></bs:smallNote>
  </c:if>
  <c:choose>
    <c:when test="${lastCheckError != null}">
      <p>
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/><c:out value="${lastCheckError}"/>.
      </p>
    </c:when>
    <c:when test="${empty newVersionBeans and empty pendingSecurityPatches}">
      <p>
        No new versions available, you are using the latest version of TeamCity.<bs:help file="Upgrade"/>
      </p>
    </c:when>

    <c:when test="${not empty newVersionBeans}">
      <div class="availableUpdatesContainer">
        <h2>Available TeamCity versions</h2>

        <p>
          There<bs:are_is val="${fn:length(newVersionBeans)}"></bs:are_is> ${fn:length(newVersionBeans)} new version<bs:s val="${fn:length(newVersionBeans)}"/> available.<bs:help file="Upgrade"/>
        </p>

        <div class="updateOptionsContainer">
          <c:forEach items="${newVersionBeans}" var="newVersionBean">
            <%--@elvariable id="newVersionBean" type="jetbrains.buildServer.controllers.autoUpdate.NewVersionBean"--%>
            <bs:_collapsibleBlock title="${newVersionBean.displayName}" id="${newVersionBean.buildNumber}block" collapsedByDefault="false" saveState="true">
              <table class="runnerFormTable">
                <tr>
                  <th>Info: </th>
                  <td>
                    <c:out value="${newVersionBean.description}"/>
                    <c:if test="${not empty newVersionBean.whatsNew || not empty newVersionBean.releaseNotes}">
                      <div>
                        <c:if test="${not empty newVersionBean.whatsNew}">
                          <a href="<c:url value="${newVersionBean.whatsNew}"/>" target="_blank" rel="noreferrer">What's New</a>
                        </c:if>
                        <c:if test="${not empty newVersionBean.releaseNotes}">
                          <c:if test="${not empty newVersionBean.whatsNew}">|</c:if>
                          <a href="<c:url value="${newVersionBean.releaseNotes}"/>" target="_blank" rel="noreferrer">Release Notes</a>
                        </c:if>
                      </div>
                    </c:if>
                    <c:if test="${not empty newVersionBean.markdownMessage}">
                      <div data-update-report-react-markdown-container="${newVersionBean.buildNumber}"></div>
                      <script type="application/javascript">
                        (() => {
                          const container = document.querySelector('[data-update-report-react-markdown-container="${newVersionBean.buildNumber}"]');
                          ReactUI.renderMarkdown(container, {children: "<bs:escapeForJs forHTMLAttribute="true" text="${newVersionBean.markdownMessage}"/>"});
                        })()
                      </script>
                    </c:if>
                    <c:if test="${empty newVersionBean.markdownMessage and not empty newVersionBean.message}">
                      <div>
                        <c:out value="${newVersionBean.message}"/>
                      </div>
                    </c:if>
                  </td>
                </tr>
                <c:if test="${newVersionBean.hasLicenses}">
                  <tr>
                    <th>Licenses compatibility: </th>
                    <td>
                      <c:choose>
                        <c:when test="${newVersionBean.activeLicensesThatShouldBeRenewedCount != 0 or newVersionBean.jwtLicenseRequiresRenewal}">
                          <bs:buildStatusIcon type="red-sign" className="warningIcon"
                          /><c:choose>
                          <c:when test="${afn:permissionGrantedGlobally('MANAGE_SERVER_LICENSES')}">
                            Some licenses are not compatible with the new version:

                            <c:if test="${newVersionBean.notCompatibleEnterpriseLicensesCount > 0}">
                              ${newVersionBean.notCompatibleEnterpriseLicensesCount} enterprise
                              <c:if test="${newVersionBean.notCompatibleAgentLicensesCount > 0}">and</c:if>
                            </c:if>
                            <c:if test="${newVersionBean.notCompatibleAgentLicensesCount > 0}">
                              ${newVersionBean.notCompatibleAgentLicensesCount} agent
                            </c:if>
                            <c:set var="notCompatibleParam">
                              <c:choose>
                                <c:when test="${intprop:getBooleanOrTrue('teamcity.ui.newLicensesPage')}">
                                  &notCompatibleWith=${util:escapeUrlForQuotes(newVersionBean.version)}
                                </c:when>
                                <c:otherwise>
                                  #_notCompatibleWith=${util:forJSIdentifier(newVersionBean.version)}
                                </c:otherwise>
                              </c:choose>
                            </c:set>
                            <a href="<c:url value='/admin/admin.html?item=license${notCompatibleParam}'/>">
                              license<bs:s val="${newVersionBean.notCompatibleEnterpriseLicensesCount + newVersionBean.notCompatibleAgentLicensesCount}"/></a>
                          </c:when>
                          <c:otherwise>
                            Some licenses are not compatible with the new version.
                          </c:otherwise>
                        </c:choose>
                        </c:when>
                        <c:otherwise>
                          <span class="icon-ok"></span>&nbsp;All the licenses are compatible with the new version.
                        </c:otherwise>
                      </c:choose>
                    </td>
                  </tr>
                </c:if>
                <tr>
                  <th>Auto update:</th>
                  <td>
                    <c:choose>
                      <c:when test="${newVersionBean.autoUpdatePossible}">
                        <jsp:include page="/admin/update.html?version=${newVersionBean.version}"/>
                      </c:when>
                      <c:otherwise>
                        Auto update is not supported for this version.
                        <bs:downloadNewVersionLink linkText="Update manually!"/>
                      </c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </table>
            </bs:_collapsibleBlock>
          </c:forEach>
        </div>

      </div>
    </c:when>
  </c:choose>

<c:if test="${not empty updateVersionCmdline}">
  <p class="registryWarn">
    <a href="javascript:;" onclick="$j('#windowsRegistryUpdate').toggle()">Updating TeamCity version in Windows registry &raquo;</a>
    <div style="display: none" id="windowsRegistryUpdate">
      <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
      Auto update will not be able to update the version of the TeamCity server in Windows registry.<br>
      To set the TeamCity version in registry to the current TeamCity version, run the following command:
      <pre>${updateVersionCmdline}</pre>
    </div>
  </p>
</c:if>

<div class="securityPatchesContainer" id="pluginsList">
  <h2>Available security updates</h2>

  <c:set var="downloadPatchesAutomatically" value="${securityPatchesMode == 'NOTIFY'}"/>
  <div class="securityPatches">
    <forms:checkbox name="securityPatchesMode" value="NOTIFY" checked="${securityPatchesMode == 'NOTIFY'}" onclick="BS.TeamCityUpdater.saveSecurityPatchesMode(this)"/>
    <label for="securityPatchesMode">Automatically download available security patches and notify administrators when they are ready to be installed</label>
    <bs:help file="upgrading-teamcity-server-and-agents#Security+Patches"/>
    <forms:saving id="saveSecurityPatchesMode" className="progressRingInline" savingTitle="Saving..."/>
  </div>

  <c:if test="${empty pendingSecurityPatches}">
    <p>There are no pending security updates for this version of TeamCity.</p>
  </c:if>


  <c:if test="${not empty pendingSecurityPatches}">
    <c:set var="needRefresh" value="${false}"/>
    <table class="parametersTable" width="100%">
      <thead>
      <tr>
        <th style="width:30%">Name</th>
        <th style="width:7%">Version</th>
        <th>Description</th>
        <th style="min-width: 150px;">Status</th>
      </tr>
      </thead>
      <c:forEach items="${pendingSecurityPatches}" var="patch">
      <tr>
        <td>
          <c:out value="${patch.displayName}"/>
        </td>
        <td>
          <c:out value="${patch.version}"/>
        </td>
        <td>
          <c:set var="id" value="${util:uniqueId()}"/>
          <div data-update-report-react-markdown-container="${id}"></div>
          <script type="application/javascript">
            (() => {
              const container = document.querySelector('[data-update-report-react-markdown-container="${id}"]');
              ReactUI.renderMarkdown(container, {children: "<bs:escapeForJs forHTMLAttribute="true" text="${patch.description}"/>"});
            })()
          </script>

          <c:if test="${not empty patch.downloadError}">
            <div class="error" style="margin-left: 0"><c:out value="${patch.downloadError}"/></div>
          </c:if>
        </td>
        <td>
          <c:choose>
            <c:when test="${not canDownloadPluginUpdate}">
              Download and install update on main server node,
              then activate update in <a href="admin.html?item=plugins&init=1">Plugins section</a> on this node.
            </c:when>
            <c:when test="${patch.downloaded}">
              Downloaded. &nbsp;

              <c:set var="patchName"><bs:escapeForJs text="${patch.name}" forHTMLAttribute="true"/></c:set>
              <forms:button id="checkForUpdatesBtn" onclick="BS.TeamCityUpdater.installDownloadedPlugin('${patchName}'); return false;">Activate ...</forms:button>
              <forms:saving id="progressInstall_${patchName}" className="progressRingInline" savingTitle="Processing..."/>
            </c:when>
            <c:when test="${not downloadPatchesAutomatically}">
              <forms:button id="downloadPatchesBtn" onclick="BS.TeamCityUpdater.downloadPlugins(this); return false;">
                ${empty patch.downloadError ? "Download" : "Re-download"}
              </forms:button>
            </c:when>
            <c:otherwise>
              <c:if test="${empty patch.downloadError}">
                Download pending
                <c:set var="needRefresh" value="${true}"/>
              </c:if>
              <c:if test="${not empty patch.downloadError}">
                <forms:button id="downloadPatchesBtn" onclick="BS.TeamCityUpdater.downloadPlugins(this); return false;">
                  ${empty patch.downloadError ? "Download" : "Re-download"}
                </forms:button>
              </c:if>
            </c:otherwise>
          </c:choose>
        </td>
      </tr>
      </c:forEach>
    </table>

    <div class="error" id="error_plugin_install" style="margin-left: 0"></div>


    <c:if test="${needRefresh}">
      <script>
        (function() {
          let timeoutThis = setTimeout(() => {
            clearTimeout(timeoutThis);
            $('updateOptionsList').refresh();
          }, 5000);
        })();
      </script>
    </c:if>

  </c:if>
</div>

</bs:refreshable>

