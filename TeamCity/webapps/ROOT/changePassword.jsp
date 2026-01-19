<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="jetbrains.buildServer.controllers.PasswordChangeController" %>
<%@ include file="/include-internal.jsp" %>
<c:set var="title" value="Change password"/>
<c:set var="link"><%=PasswordChangeController.URL_PATH%></c:set>
<bs:externalPage>
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/forms.css
      /css/maintenance-initialPages-common.css
      /css/initialPages.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/bs/bs.js
      /js/bs/forms.js
      /js/bs/resetPassword/resetPassword.js
    </bs:linkScript>
    <bs:reactUi />
    <script>
      ReactUI.setGlobalTheme()
    </script>
    <bs:ua/>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:_loginPageDecoration id="loginPage" title="${title}">
      <p id="resetPasswordResult" style="display: none;"></p>
      <div id="errorMessage" style="display: none;"></div>
      <div id="formNote">Current password does not meet the requirements set on the server and has to be changed</div>
      <c:choose>
        <%--@elvariable id="emailVerified" type="java.lang.Boolean"--%>
        <%--@elvariable id="maskedEmail" type="java.lang.String"--%>
        <c:when test="${emailVerified}">
          <form id="changePasswordForm" class="emailForm" method="post" action="<c:url value='${link}'/>" onsubmit="BS.SendResetEmailForm.submit(); return false;">
            <div class="loginDescription">The password reset link is sent to the email ${maskedEmail}. <br/></div>
          </form>
        </c:when>
        <c:otherwise>
          <p>Your email is not verified. Please verify email first or contact the administrator</p>
        </c:otherwise>
      </c:choose>
      <p class="registerUser">
        <span><a href="<c:url value='/login.html'/>">Login page</a></span>
      </p>
    </bs:_loginPageDecoration>
  </jsp:attribute>
</bs:externalPage>
