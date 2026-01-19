<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>
<jsp:useBean id="adminEditUserForm" type="jetbrains.buildServer.controllers.admin.users.AdminEditUserForm" scope="request"/>
<c:set var="notifiersBean" value="${adminEditUserForm.notifiersBean}"/>
<c:set var="selectedNotifier" value="${param['notificatorType']}"/>
<c:if test="${empty selectedNotifier}">
  <c:set var="selectedNotifier"><%=adminEditUserForm.getNotifiersBean().getAvailableNotifiers().get(0).getNotificatorType()%></c:set>
</c:if>

<c:url value='/admin/editUser.html' var="url">
  <c:param name="userId" value="${adminEditUserForm.editee.id}"/>
  <c:param name="cameFromTitle" value="${adminEditUserForm.cameFromSupport.cameFromTitle}"/>
  <c:param name="cameFromUrl" value="${adminEditUserForm.cameFromSupport.cameFromUrl}"/>
  <c:param name="tab" value="userNotifications"/>
  <c:param name="init" value="1"/>
</c:url>
<n:availableNotifiers urlPattern="${url}&notificatorType=##notifierType##" selectedNotifier="${selectedNotifier}" availableNotifiersBean="${notifiersBean}"/>

<jsp:include page="/notifierSettings.html?userId=${adminEditUserForm.editee.id}&adminMode=true">
  <jsp:param name="cameFromUrl" value="${adminEditUserForm.cameFromSupport.cameFromUrl}"/>
  <jsp:param name="cameFromTitle" value="${adminEditUserForm.cameFromSupport.cameFromTitle}"/>
  <jsp:param name="notificatorType" value="${selectedNotifier}"/>
</jsp:include>
