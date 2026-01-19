<%@ page import="jetbrains.buildServer.controllers.resetPassword.ForgotPasswordController" %>
<%@ include file="/include-internal.jsp"%>
<c:set var="link"><%=ForgotPasswordController.URL_PATH%></c:set>
<script type="text/javascript">
  $j('#resetPasswordContainer').append('<a href="<c:url value="${link}"/>">Reset password</a>');
</script>