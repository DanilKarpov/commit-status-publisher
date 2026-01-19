<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="buildTypeId" type="java.lang.String" scope="request"/>
<jsp:useBean id="featureId" type="java.lang.String" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<jsp:useBean id="notifier" type="jetbrains.buildServer.notification.BuildTypeNotifierDescriptor" scope="request"/>

<c:choose>
  <c:when test="${not empty notifier.editParametersUrl}">
    <jsp:include page="${notifier.editParametersUrl}?buildTypeId=${buildTypeId}&featureId=${featureId}"/>
  </c:when>
  <c:otherwise>
    <c:forEach items="${notifier.parameters}" var="parameter">
      <tr>
        <th>
            ${util:forJS(parameter.value.parameterTypeArguments["description"], false, true)}:<c:if test="${parameter.value.parameterTypeArguments['required'] == 'true'}"><l:star/></c:if>
        </th>
        <td>
          <c:choose>
            <c:when test="${parameter.value.parameterType == 'password'}">
              <props:passwordProperty name="${parameter.key}" className="longField buildTypeNotifierInput"/>
            </c:when>

            <c:otherwise>
              <props:textProperty name="${parameter.key}" className="longField buildTypeNotifierInput"/>
            </c:otherwise>
          </c:choose>

          <span class="error" id="error_${parameter.key}"></span>
        </td>
      </tr>
    </c:forEach>
  </c:otherwise>
</c:choose>

<jsp:include page="/notificationRules.html">
  <jsp:param name="notifiactorType" value="${notifier.type}"/>
  <jsp:param name="filterType" value="project"/>

  <jsp:param name="filter" value="_Root"/>
  <jsp:param name="newRule" value="true"/>
  <jsp:param name="featureId" value="${util:forJS(featureId, true, false)}"/>
  <jsp:param name="holderId" value="${util:forJS(buildTypeId, true, false)}"/>
</jsp:include>

<bs:executeOnce id="attachPopusToBuildFeatureParameters">
  <script>
    BS.AvailableParams.attachPopupsTo('settingsId=${buildTypeId}', ".buildTypeNotifierInput");
  </script>
</bs:executeOnce>
