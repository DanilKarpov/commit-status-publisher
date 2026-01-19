<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ page import="jetbrains.buildServer.serverSide.crypt.RSACipher" %>

<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="uuidIsSuspicious" type="java.lang.Boolean"--%>

<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<c:set var="escapedPageUrl" value="<%=WebUtil.encode(pageUrl)%>"/>
<jsp:useBean id="loginConfig" scope="request" type="jetbrains.buildServer.serverSide.ServerSettings"/>
<jsp:useBean id="serverConfigForm" scope="request" type="jetbrains.buildServer.controllers.admin.ServerConfigForm"/>
<c:set var="internalDbWarn">
  <c:if test="${serverConfigForm.hsqldb}">
    <div class="smallNote unscalableDbWarning">
      <bs:buildStatusIcon type="red-sign" className="warningIcon"/>For production purposes, switching to a standalone database is recommended to achieve better performance and reliability.
      See <a href="<bs:helpUrlPrefix/>Migrating+to+an+External+Database" target="_blank" rel="noreferrer">Migration Instructions</a>.
    </div>
  </c:if>
</c:set>

<div id="serverConfigGeneral">
  <div class="serverConfigPage">
    <bs:refreshable pageUrl="${pageUrl}" containerId="serverSettings">
      <bs:messages key="serverSettingsSaved"/>

      <c:if test="${uuidIsSuspicious and afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
        <div id="serverInstallationChanged"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>
          This TeamCity installation may have been moved or copied. In order to properly configure your installation please
          select one of the following options and click 'Confirm':
          <div>
            <div class="actionChoose"><input type="radio" name="copiedOrMoved" id="serverMoved"/><label for="serverMoved">moved</label></div>
            <div class="actionChoose"><input type="radio" name="copiedOrMoved" id="serverCopied"/><label for="serverCopied">copied (or unsure)</label></div>
            <div><forms:submit id="serverCopiedOrMovedConfirm" label="Confirm"/></div>
          </div>
        </div>
      </c:if>

      <form action="<c:url value='/admin/serverConfigGeneral.html'/>" method="post" onsubmit="return BS.ServerConfigForm.submitSettings()">
        <input type="hidden" name="publicKey" id="publicKey" value="<c:out value='<%=RSACipher.getHexEncodedPublicKey()%>'/>"/>
        <table class="runnerFormTable">
          <tr class="groupingTitle">
            <td colspan="2">TeamCity Configuration
              <c:if test="${afn:permissionGrantedGlobally('MANAGE_SERVER_INSTALLATION')}">
                  / <a href="?item=diagnostics&init=1">Diagnostics</a>
              </c:if>
            </td>
          </tr>
          <tr>
            <th>Database: </th>
            <td>
              Database&nbsp;type: <c:out value="${serverConfigForm.dbTypeName}"/><br/>
              <c:if test="${not serverConfigForm.hsqldb}">
                Connection&nbsp;URL: <span class="mono"><c:out value="${serverConfigForm.dbConnectionString}"/></span>
              </c:if>
              <c:if test="${serverConfigForm.hsqldb}">
                ${internalDbWarn}
              </c:if>
            </td>
          </tr>
          <tr>
            <th>Data directory:<bs:help file="TeamCity+Data+Directory"/></th>
            <td>
              <span id="dataDirectory"><c:out value="${serverConfigForm.dataDirectory}"/></span>
              <c:if test="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
                <a href="<c:url value='/admin/admin.html?item=diagnostics&tab=dataDir'/>" style="margin-left: 20px; font-size: 90%;">Browse</a>
              </c:if>
            </td>
          </tr>
          <tr>
            <th>Artifact directories: </th>
            <td>
              <forms:textField name="artifactDirectories" expandable="true" value="${serverConfigForm.artifactDirectories}" className="longField"/>
              <input type="hidden" id="originalArtifactDirectories" value="<c:out value="${serverConfigForm.artifactDirectories}"/>"/>
              <span class="error" id="artifactDirectoriesError"></span>
              <span class="smallNote">
                New-line delimited paths to artifact directories used by the server.
                Artifacts for all new builds are published under the first directory in the list.
                Relative paths are relative to TeamCity data directory: <c:out value="${serverConfigForm.dataDirectory}"/>.
              </span>
            </td>
          </tr>
          <tr>
            <th>Caches directory: </th>
            <td>
              <c:out value="${serverConfigForm.cacheDirectory}"/>
            </td>
          </tr>
          <tr>
            <th><label for="rootUrl">Server URL:</label><bs:help file="Configuring+Server+URL"/></th>
            <td>
              <forms:textField name="rootUrl" style="width: 370px;" value="${serverConfigForm.rootUrl}"/>
              <span class="error" id="invalidRootUrl"></span>
            </td>
          </tr>

          <tr class="groupingTitle">
            <td colspan="2">Builds Settings</td>
          </tr>
          <tr>
            <th><label for="maxArtifactSize">Maximum build artifact file size:</label></th>
            <td>
              <forms:textField name="maxArtifactSize" value="${serverConfigForm.maxArtifactSize}" size="10" maxlength="20"/>
              <span class="error" id="invalidMaxArtifactSize"></span>
              <bs:smallNote>in bytes. <it>KB, MB, GB or TB</it> suffixes are allowed, -1 indicates no limit</bs:smallNote>
            </td>
          </tr>
          <tr>
            <th><label for="maxArtifactsNumber">Maximum number of artifacts per build:</label></th>
            <td>
              <forms:textField name="maxArtifactsNumber" value="${serverConfigForm.maxArtifactsNumber}" size="10" maxlength="20"/>
              <span class="error" id="invalidMaxArtifactsNumber"></span>
              <bs:smallNote>-1 indicates no limit</bs:smallNote>
            </td>
          </tr>
          <tr>
            <th><label for="defaultExecutionTimeout">Default build execution timeout:</label></th>
            <td>
              <forms:textField name="defaultExecutionTimeout" value="${serverConfigForm.defaultExecutionTimeout}" size="6" maxlength="8"/> minutes
              <span class="error" id="invalidDefaultExecutionTimeout"></span>
              <bs:smallNote>0 and negative values indicate no execution timeout</bs:smallNote>
            </td>
          </tr>

          <tr class="groupingTitle">
            <td colspan="2">Version Control Settings</td>
          </tr>
          <tr>
            <th><label for="defaultModificationCheckInterval">Default VCS changes check interval:</label></th>
            <td><forms:textField name="defaultModificationCheckInterval" size="6" maxlength="8" value="${serverConfigForm.defaultModificationCheckInterval}"/> seconds
              <span class="error" id="invalidDefaultModificationCheckInterval"></span>
              <div class="checkboxSectionUnderInput">
                <label>
                <forms:checkbox name="minimumCheckIntervalEnforced" checked="${serverConfigForm.minimumCheckIntervalEnforced}"/>
                Enforce this value as a minimum for all VCS Roots
                </label>
              </div>
            </td>
          </tr>
          <tr>
            <th><label for="defaultQuietPeriod">Default VCS trigger quiet period:</label></th>
            <td><forms:textField name="defaultQuietPeriod" size="6" maxlength="8" value="${serverConfigForm.defaultQuietPeriod}"/> seconds
              <span class="error" id="invalidDefaultQuietPeriod"></span></td>
          </tr>
          <tr class="groupingTitle">
            <td colspan="2">Encryption Settings</td>
          </tr>
          <tr>
            <th><label for="customEncryptionStrategy">Use custom encryption key:</label><bs:help file="Encryption+Settings"/></th>
            <td><forms:checkbox name="customEncryptionStrategy" checked="${serverConfigForm.customEncryptionStrategy or serverConfigForm.encryptionViaEnvVarConfigured}"
                                disabled="${serverConfigForm.encryptionViaEnvVarConfigured}"
                                onclick="defaulEncryptionStrategyChanged(this.checked)"/>
              <c:if test="${serverConfigForm.encryptionViaEnvVarConfigured}">
                <bs:smallNote>The custom encryption key is imported from the TEAMCITY_ENCRYPTION_KEYS environment variable<bs:help file="Configuring+Server+URL"/></bs:smallNote>
                <bs:smallNote><a onclick="generateROAesKey(event)">generate new encryption key</a></bs:smallNote>
              </c:if>
            </td>
          </tr>
          <c:if test="${serverConfigForm.encryptionViaEnvVarConfigured}">
            <tr id="readOnlyEncryptionKey" style="display: none">
              <th><label for="aesKey">New encryption key:</label></th>
              <td>
                <div id="clipboardKey" class="clipboard-btn tc-icon icon16 tc-icon_copy" style="float: left;" data-clipboard-action="copy"
                     data-clipboard-target="#generatedReadOnlyKey"></div>
                <span id="generatedReadOnlyKey"></span>
              </td>
            </tr>
          </c:if>
          <c:choose>
            <c:when test="${serverConfigForm.customEncryptionStrategy and not serverConfigForm.encryptionViaEnvVarConfigured}">
              <tr id="encryptionKey">
            </c:when>
            <c:otherwise>
              <tr id="encryptionKey" style="display: none">
            </c:otherwise>
          </c:choose>
              <th><label for="aesKey">Custom encryption key:<l:star/></label></th>
              <td><forms:passwordField name="aesKey" size="24" maxlength="24" style="width: 370px;" encryptedPassword="${serverConfigForm.defaultEncryptionKey}"/>
                <button type="button" id="generateKeyButton" class="btn btn_mini" style="margin-left: 10px; padding: 2px 14px 2px;" onclick="generateAesKey(event);">Generate key</button>
                <span class="error" id="invalidEncryptionKey"></span>
                <bs:smallNote>128 bit key encoded with Base64 is allowed <bs:help urlPrefix="https://en.wikipedia.org/wiki/Base64" file=""/> </bs:smallNote>
              </td>
          </tr>
          <c:if test="${intprop:getBooleanOrTrue('teamcity.internal.domainIsolationProtectionFeature.enabled')}">
            <tr class="groupingTitle">
              <td colspan="2">Artifacts Domain Isolation</td>
            </tr>
            <tr>
              <th><label for="domainIsolationEnabled">Enable isolation protection:</label><bs:help file="Artifacts+Domain+Isolation"/></th>
              <td>
                <forms:checkbox id="domainIsolationEnabled" name="domainIsolationEnabled" checked="${serverConfigForm.domainIsolationEnabled}"/>
                <span class="error" id="invalidDomainIsolationEnabled"></span>
                <bs:smallNote>Secure the server by isolating user-supplied content under a separate domain. Note: the build results' tabs which rely on artifacts for representing build data (for example, custom reports) will be displayed only if the proper artifacts' URL is specified below.</bs:smallNote>
              </td>
            </tr>
            <tr id="domainIsolationArtifactsRootUrlSettingsRow">
              <th><label for="artifactsRootUrl">Artifacts URL:</label></th>
              <td>
                <forms:textField id="domainIsolationArtifactsRootUrlInput" name="artifactsRootUrl" style="width: 370px;" value="${serverConfigForm.artifactsRootUrl}"/>
                <span class="error" id="invalidArtifactsRootUrl"></span>
                <bs:smallNote>Specify a URL to serve build artifacts from. The URL must be different from the Server URL. Read <bs:helpLink file="Artifacts+Domain+Isolation">our documentation</bs:helpLink> on this topic.</bs:smallNote>
              </td>
            </tr>
          </c:if>
        </table>

        <c:if test="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
          <div class="saveButtonsBlock">
            <forms:submit label="Save"/>
            <input type="hidden" id="submitSettings" name="submitSettings" value="store"/>
            <forms:saving/>
          </div>
        </c:if>

      </form>

      <forms:modified/>

      <script type="text/javascript">
        BS.ServerConfigForm.setupEventHandlers();
        BS.ServerConfigForm.setModified(${serverConfigForm.stateModified});
        BS.VisibilityHandlers.updateVisibility('serverSettings');
      </script>

    </bs:refreshable>

    <div class="clr"></div>

    <ext:includeExtensions placeId="<%=PlaceId.ADMIN_SERVER_CONFIGURATION%>"/>
  </div>
</div>

<script type="text/javascript">

  function generateKey(onSuccess) {
    BS.ajaxRequest(window['base_uri'] + '/admin/action.html', {
      parameters: {
        action: 'generateKey'
      },
      onComplete: function (transport) {
        if (transport.status != 200) {
          alert("Error: status " + transport.status);
        } else if (transport.responseXML && transport.responseXML.error) {
          alert(transport.responseXML.error);
        } else {
          onSuccess(transport)
        }
      }
    });
  }

  function generateROAesKey(event) {
    event.stopPropagation();
    generateKey(function (transport) {
      $j('#readOnlyEncryptionKey').show()
      $j('#generatedReadOnlyKey').text(transport.responseXML.firstChild.textContent);
    });
  }


  function generateAesKey(event) {
    event.stopPropagation();
    $("generateKeyButton").textContent = 'Regenerate key';
    generateKey(function (transport) {
      var style = $j('input[name="aesKey"]')[0].getAttribute("style");
      $j('input[name="aesKey"]')[0].setAttribute("style", style + " -webkit-text-security: none;");
      $j('input[name="aesKey"]').val(transport.responseXML.firstChild.textContent).click();
    });
  }

  function defaulEncryptionStrategyChanged(checked) {
    if (checked)
      document.getElementById("encryptionKey").style.display = 'table-row';
    else document.getElementById("encryptionKey").style.display = 'none';
  }

  function isolationProtectionChanged(checked) {
    if(checked) {
      $j('#domainIsolationArtifactsRootUrlSettingsRow').show();
    } else {
      $j('#domainIsolationArtifactsRootUrlSettingsRow').hide();
      $j('#domainIsolationArtifactsRootUrlInput').val("");
    }
  }

  $j(function() {
    <c:if test="${not afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
      BS.ServerConfigForm.setReadOnly();
    </c:if>
    <c:if test="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
      $j('#serverCopiedOrMovedConfirm').click(function() {
        var selected = $j('input[name=copiedOrMoved]:checked').attr('id');
        if (selected) {
          if (selected == 'serverMoved') {
            BS.ajaxRequest(window['base_uri'] + '/admin/action.html', {
              parameters: {
                action: 'confirmUUID'
              },
              onComplete: function (transport) {
                if (transport.status != 200) {
                  alert("Error: status " + transport.status);
                } else if (transport.responseXML && transport.responseXML.error) {
                  alert(transport.responseXML.error);
                } else {
                  $j('#serverInstallationChanged').remove();
                }
              }
            });
          } else if (selected == 'serverCopied') {
            BS.ajaxRequest(window['base_uri'] + '/admin/action.html', {
              parameters: {
                action: 'regenerateUUID'
              },
              onComplete: function (transport) {
                if (transport.status != 200) {
                  alert("Error: status " + transport.status);
                } else if (transport.responseXML && transport.responseXML.error) {
                  alert(transport.responseXML.error);
                } else {
                  $j('#serverInstallationChanged').remove();
                }
              }
            });
          }
        }
      });
      $j(document).ready(function () {
        BS.Clipboard('#clipboardKey');
        isolationProtectionChanged($j('#domainIsolationEnabled').is(":checked") || $j('#domainIsolationArtifactsRootUrlInput').val());
        $j('#domainIsolationEnabled').change(function () {
          isolationProtectionChanged(this.checked);
        });
      });
    </c:if>
  });
</script>
