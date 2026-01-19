<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="extensionError2BT" value="${healthStatusItem.additionalData['extensionError2BT']}"/>
<%--@elvariable id="cleanupState" type="jetbrains.buildServer.serverSide.cleanup.CleanupProcessState"--%>
<c:set var="cleanupState" value="${healthStatusItem.additionalData['cleanupState']}"/>

<c:if test="${extensionError2BT != null && cleanupState != null}">
  <%--@elvariable id="extensionErrors" type="java.util.Collection<jetbrains.buildServer.serverSide.impl.cleanup.ExtensionError>"--%>
  <c:set var="extensionErrors" value="${extensionError2BT.keySet()}"/>

  <div>
    The following errors occurred when calling extensions during the
    <c:if test="${cleanupState.inProgress}">current</c:if><c:if test="${!cleanupState.inProgress}">last finished</c:if> clean-up.
    See clean-up logs for more details.
    <br>
    <br>
  </div>

  <c:forEach items="${extensionErrors}" var="extensionError">
    <%--@elvariable id="buildTypePairs" type="java.util.List<com.intellij.openapi.util.Pair<jetbrains.buildServer.serverSide.SBuildType, java.lang.String>>"--%>
    <c:set var="buildTypePairs" value="${extensionError2BT.get(extensionError)}"/>

    <div>Extension '<c:out value="${extensionError.extensionName}"/>' : <c:out value="${extensionError.errorMessage}"/></div>
    <c:if test="${buildTypePairs.size() > 1}">
      Affected configurations:
      <ol style="margin: 0;">
        <c:forEach items="${buildTypePairs}" var="buildTypeAndId">
          <c:set var="buildType" value="${buildTypeAndId.first}"/>
          <c:set var="buildTypeId" value="${buildTypeAndId.second}"/>
          <li>
            <c:if test="${buildType != null}">
              <bs:buildTypeLinkFull buildType="${buildType}"/>
            </c:if>
            <c:if test="${buildType == null}">
              Deleted configuration with id: <c:out value="${buildTypeId}"/>
            </c:if>
          </li>
        </c:forEach>
      </ol>
    </c:if>
    <c:if test="${buildTypePairs.size() == 1}">
      Affected configuration:
      <c:set var="buildTypeAndId" value="${buildTypePairs.get(0)}"/>
      <c:set var="buildType" value="${buildTypeAndId.first}"/>
      <c:set var="buildTypeId" value="${buildTypeAndId.second}"/>
      <c:if test="${buildType != null}">
        <bs:buildTypeLinkFull buildType="${buildType}"/>
      </c:if>
      <c:if test="${buildType == null}">
        Deleted configuration with id: <c:out value="${buildTypeId}"/>
      </c:if>
      <br>
    </c:if>
    <br>
  </c:forEach>
</c:if>