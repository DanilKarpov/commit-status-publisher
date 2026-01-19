<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="include-internal.jsp" %>
<jsp:useBean id="showMandatory2FAMessage" scope="request" type="java.lang.Boolean"/>
<bs:externalPage>
  <jsp:attribute name="page_title">2FA</jsp:attribute>
  <jsp:attribute name="body_include">
    <div id="screen"></div>
    <script>
      ReactUI.renderTwoFactorAuthLoginPage('screen', {showMandatory2FAMessage: ${showMandatory2FAMessage}})
    </script>
  </jsp:attribute>
</bs:externalPage>
