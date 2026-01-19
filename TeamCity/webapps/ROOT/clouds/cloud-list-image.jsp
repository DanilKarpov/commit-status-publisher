<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="clouds" tagdir="/WEB-INF/tags/clouds" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:useBean id="profileInfo" scope="request" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabFormProfileInfo"/>
<jsp:useBean id="image" scope="request" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabFormImageInfo"/>

<table class="cloudSettings">
  <tr class="image">
    <c:set var="imageId"><bs:escapeForJs forHTMLAttribute="true" text="${image.uniqueId}"/></c:set>
    <td class="noRightBorder">
      <c:set var="imageName"><bs:escapeForJs forHTMLAttribute="true" text="${image.name}"/></c:set>
      <c:choose>
        <c:when test="${not empty image.agentType}">
          <bs:agentDetailsFullLink agentType="${image.agentType}"
                                   imageWarningsMsg="${image.imageWarningsAsHtml}"
          ><c:out value="${imageName}"/> </bs:agentDetailsFullLink>
        </c:when>
        <c:otherwise><c:out value="${imageName}"/> </c:otherwise>
      </c:choose>
      <c:if test="${not image.containsAgent}">
        <c:set var="escapedServerUrl"><bs:escapeForJs forHTMLAttribute="true" text="${image.serverUrlForCreatingAgent}"/></c:set>
        <span <bs:tooltipAttrs width="350px"
                               text='No agents connected after instance start. Please check the image has TeamCity agent configured and it can connect to the server using ${escapedServerUrl} address. Start the instance manually to check for agent again.'/>
            style="color: #a90f1a; font-weight:bold;">(!)</span>
      </c:if>
      <clouds:cloudProblemsLink controlId="error_${imageId}" problems="${image.problems}">
        Image Error
      </clouds:cloudProblemsLink>
      <clouds:cloudProblemContent controlId="error_${imageId}" problems="${image.problems}"/>
    </td>
    <td class="buttons">
      <authz:authorize anyPermission="START_STOP_CLOUD_AGENT" projectIds="${image.agentType.agentPool.projectIds}" checkGlobalPermissions="true">
        <forms:saving id="startImageLoader_${imageId}" className="progressRingInline"/>
        <c:set var="canNotStartMoreInstancesReason"><bs:escapeForJs forHTMLAttribute="true" text="${image.canNotStartMoreInstancesReason}"/></c:set>
        <c:choose>
          <c:when test="${image.canStartMoreInstances || image.isQuotaLimitReached}">
          <input id="startImageButton_${imageId}" type="button" class="btn btn_mini" value="Start"
                 <c:if test="${image.isQuotaLimitReached}">disabled="disabled" title="${canNotStartMoreInstancesReason}" </c:if>
                 onclick="return BS.Clouds.startInstance('<bs:forJs>${imageId}</bs:forJs>', '<bs:forJs>${profileInfo.profile.projectId}</bs:forJs>', '<bs:forJs>${profileInfo.id}</bs:forJs>', '<bs:escapeForJs forHTMLAttribute="true" text="${image.id}"/>');"/>
          </c:when>
          <c:otherwise>
            <span class="agentVersion" <bs:tooltipAttrs text="${canNotStartMoreInstancesReason}"/>><bs:buildStatusIcon type="red-sign"/></span>
          </c:otherwise>
        </c:choose>
      </authz:authorize>
    </td>
  </tr>
  <c:if test="${not image.hasErrors}">
    <bs:changeRequest key="image" value="${image.image}">
      <jsp:include page="/clouds/cloud-include-image-details.html"/>
    </bs:changeRequest>
  </c:if>
  <c:choose>
    <c:when test="${image.hasErrors}"> </c:when>
    <c:when test="${not empty image.instances}">
      <c:forEach items="${image.instances}" var="instance">

        <bs:changeRequest key="instance" value="${instance}">

          <authz:authorize anyPermission="START_STOP_CLOUD_AGENT" projectIds="${image.agentType.agentPool.projectIds}" checkGlobalPermissions="true">
            <jsp:attribute name="ifAccessGranted">
              <c:set var="userCanStartInstance" value="true"/>
            </jsp:attribute>
            <jsp:attribute name="ifAccessDenied">
              <c:set var="userCanStartInstance" value="false"/>
            </jsp:attribute>
          </authz:authorize>

          <jsp:include page="cloud-list-instance.jsp">
            <jsp:param name="userCanStart" value="${userCanStartInstance}"/>
          </jsp:include>
          <c:remove var="userCanStartInstance" scope="request"/>
        </bs:changeRequest>
      </c:forEach>
    </c:when>
    <c:otherwise>
      <tr class="noInstance">
        <td class="instanceName" colspan="2">There are no running instances</td>
      </tr>
    </c:otherwise>
  </c:choose>
</table>
