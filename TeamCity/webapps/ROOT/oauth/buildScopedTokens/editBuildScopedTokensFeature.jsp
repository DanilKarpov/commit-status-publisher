<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.buildScopedTokens.BuildScopedTokensSettings" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<jsp:useBean id="featureSettingsUrl" scope="request" type="java.lang.String"/>
<jsp:useBean id="providers" scope="request" type="java.util.Collection<jetbrains.buildServer.serverSide.oauth.buildScopedTokens.BuildScopedTokensSettings>"/>
<jsp:useBean id="projectId" scope="request" type="java.lang.String"/>
<jsp:useBean id="settingsId" scope="request" type="java.lang.String"/>

<c:url value="${featureSettingsUrl}" var="settingsUrl"/>



<script type="text/javascript">
  BS.BuildScopedTokensFeature = OO.extend(BS.BuildFeatureDialog, {
    showSettings: function () {
      var url = '${settingsUrl}?settingsId=' + $("<%=BuildScopedTokensSettings.SETTINGS_ID_PARAM%>").value + "&projectId=${projectId}";
      $j("#providerSettings").html("");
      $j.get(url, function (xhr) {
        $j("#providerSettings").html(xhr);
        BS.BuildFeatureDialog.recenterDialog();
      });
      return false;
    }
  });
</script>

<tr>
  <th>
    <label for="<%=BuildScopedTokensSettings.SETTINGS_ID_PARAM%>">Provider: </label>
  </th>
  <td>
    <props:selectProperty name="<%=BuildScopedTokensSettings.SETTINGS_ID_PARAM%>" onchange="BS.BuildScopedTokensFeature.showSettings()" enableFilter="true" style="width: 28em;">
      <c:forEach var="provider" items="${providers}">
        <props:option value="${provider.id}"><c:out value="${provider.displayName}"/></props:option>
      </c:forEach>
    </props:selectProperty>
  </td>
</tr>

<tbody id="providerSettings">
<jsp:include page="${featureSettingsUrl}">
  <jsp:param name="settingsId" value="${settingsId}"/>
  <jsp:param name="projectId" value="${projectId}"/>
</jsp:include>
</tbody>