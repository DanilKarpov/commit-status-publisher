<%@include file="/include-internal.jsp"%>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ page import="jetbrains.buildServer.serverSide.healthStatus.ItemSeverity" %>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="canBeEnabledOnCurrentNode" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="reason" value="${healthStatusItem.additionalData['reason']}"/>
<c:set var="confirmText">
  Enabling of versioned settings can commit projects configuration files from this server to VCS if files in VCS are different.<br>
  <p><bs:itemSeverity severity="${ItemSeverity.WARN}"/> Note: it is not recommended to enable versioned settings on a test server which is using a copy of data from the production server,
  because the production server may not be able to load changed configuration files.</p>
  <p>Are you sure you want to continue?</p>
</c:set>

<script type="text/javascript">
  enableVersionedSettings = function() {
    var action = function() {
      $j('#enablingVersionedSettings').show();
      BS.ajaxRequest('<c:url value="/admin/versionedSettingsActions.html"/>', {
        parameters: Object.toQueryString({action: 'enableVersionedSettings'}),
        onComplete: function (transport) {
          BS.XMLResponse.processErrors(transport.responseXML, {}, function (id, elem) {
            alert(elem.firstChild.nodeValue);
          });
          BS.reload();
        }
      });
    };

    BS.confirmDialog.show({
      text: '<bs:escapeForJs text="${confirmText}"/>',
      title: "Enable versioned settings",
      actionButtonText:  "Enable",
      cancelButtonText: 'Cancel',
      action: action
    });
  };
</script>
<c:set var="serverAdmin" value="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}"/>
<c:set var="msg">
  Versioned settings are <bs:helpLink file="Storing+Project+Settings+in+Version+Control" anchor="enableAfterUpgrade">globally disabled</bs:helpLink> on the server, reason: <c:out value="${reason}"/>.
</c:set>
<c:choose>
  <c:when test="${showMode == inplaceMode}">${msg}</c:when>
  <c:otherwise><div>${msg}</div></c:otherwise>
</c:choose>
<c:if test="${serverAdmin}">
  <div style="margin-top: 0.5em;">
    <c:choose>
      <c:when test="${canBeEnabledOnCurrentNode}">
        Click "Enable" to commit the current projects configuration files to VCS.
      </c:when>
      <c:otherwise>
        Log in to the main node to enable the versioned settings.
      </c:otherwise>
    </c:choose>

    <c:if test="${canBeEnabledOnCurrentNode}">
      <div style="margin-top: 0.5em;">
        <input type="button" class="btn btn_mini" value="Enable" onclick="enableVersionedSettings()"/>
        <forms:saving id="enablingVersionedSettings" style="float: none; margin-left: 0.5em;"/>
      </div>
    </c:if>
  </div>
</c:if>
<c:if test="${not empty projects}">
  <div style="margin-top: 0.5em;">
    <a href="javascript:;" onclick="$j('#disabledVsettingsAffectedProjects_${showMode}').toggle()">Show project<bs:s val="${fn:length(projects)}"/> with converted settings &raquo;</a>
  </div>
  <ul id="disabledVsettingsAffectedProjects_${showMode}" style="display: none; margin-left: 0em;">
    <c:forEach var="p" items="${projects}">
      <li><admin:projectName project="${p}" addToUrl="&tab=versionedSettings&subTab=config"/></li>
    </c:forEach>
  </ul>
</c:if>
