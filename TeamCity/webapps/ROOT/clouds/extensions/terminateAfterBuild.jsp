<%--
  Created by IntelliJ IDEA.
  User: sergeypak
  Date: 01/09/2017
  Time: 14:34
  To change this template use File | Settings | File Templates.
--%>
<%@include file="/include-internal.jsp" %>

<jsp:useBean id="profile" scope="request" type="jetbrains.buildServer.clouds.CloudProfile"/>
<jsp:useBean id="instance" scope="request" type="jetbrains.buildServer.clouds.CloudInstance"/>
<jsp:useBean id="isExpired" scope="request" type="java.lang.Boolean"/>
<jsp:useBean id="buildRef" scope="request" type="java.util.concurrent.atomic.AtomicReference"/>

<authz:authorize allPermissions="START_STOP_CLOUD_AGENT,VIEW_AGENT_CLOUDS" projectId="${profile.projectId}">
  <c:if test="${instance.status.canManuallyTerminate}">
    <c:set var="showInstanceStatus" value="${false}"/>
    <c:set var="instanceId"><bs:escapeForJs forHTMLAttribute="true" text="${instance.instanceId}"/></c:set>
    <div id="stopInstanceDiv_instance">
      <a href="#" onclick="if (confirm('Are you sure you want to <c:if test="${isExpired}"
      >FORCE </c:if>stop cloud instance \'${instanceId}\'<c:if test="${isExpired and buildRef.get() != null}"
      >\nthis can interrupt current build</c:if>?')) BS.Clouds.stopInstance('instance','<bs:escapeForJs
          forHTMLAttribute="true" text="${profile.projectId}"/>','<bs:escapeForJs
          forHTMLAttribute="true" text="${profile.profileId}"/>','<bs:escapeForJs
          forHTMLAttribute="true" text="${instance.imageId}"/>','<bs:escapeForJs
          forHTMLAttribute="true" text="${instance.instanceId}"/>',
        <bs:forJs>${isExpired}</bs:forJs>); return false;"><c:if test="${isExpired}">Force </c:if>Stop<c:if test="${not isExpired}"> instance after current build</c:if></a>
      <c:if test="${isExpired}">
        (instance will be stopped <c:if test="${buildRef.get() != null}">after current build</c:if><c:if test="${buildRef.get() == null}">soon</c:if>)
      </c:if>
    </div>
    <div id="stoppingInstanceDiv_instance" style="display:none;">
      <forms:saving className="progressRingInline"/> Stopping...
    </div>
  </c:if>
</authz:authorize>
