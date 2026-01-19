<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="jetbrains.buildServer.controllers.resetPassword.ForgotPasswordController" %>
<%@ page import="jetbrains.buildServer.controllers.resetPassword.ResetPasswordController" %>
<%@ page import="static jetbrains.buildServer.controllers.resetPassword.ForgotPasswordController.DISABLED_ERROR_MSG" %>
<%@ include file="/include-internal.jsp" %>
<c:set var="title" value="Reset password"/>
<c:set var="link"><%=ForgotPasswordController.URL_PATH%></c:set>
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
    <script type="text/javascript">
      $j(document).ready(function($) {
        $j("#input_email").focus();
      });
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:_loginPageDecoration id="loginPage" title="${title}">
      <p id="resetPasswordResult" style="display: none;"></p>
      <div id="errorMessage" style="display: none;"></div>

      <c:choose>
        <c:when test="${enabled}">
           <form id="resetPasswordForm" class="emailForm" method="post" action="<c:url value='${link}'/>" onsubmit="BS.SendResetEmailForm.submit(); return false;">
             <div class="loginDescription">Enter an email for a user registered on this server. <br/> The password reset link will be sent to the email.</div>

             <div>
               <label for="input_email">Email</label>
               <input class="text" id="input_email" type="text" name="email"/>
               <span class="error" id="input_email_error" style="margin: 0.5em 0 0 0;"></span>
             </div>
             <div>
               <div class="loader-cell"><forms:saving className="progressRingSubmitBlock" savingTitle="Sending reset password email"/></div>
               <noscript>
                 <div class="noJavaScriptEnabledMessage">
                   Please enable JavaScript in your browser to proceed with the registration.
                 </div>
               </noscript>
             </div>
             <div class="buttons">
               <input class="btn loginButton" type="submit" value="Next"/>
             </div>
           </form>
        </c:when>
        <c:otherwise>
          <c:set var="error" value="<%=DISABLED_ERROR_MSG%>"/>
          <p>${error}</p>
        </c:otherwise>
      </c:choose>
      <p class="registerUser">
        <span><a href="<c:url value='/login.html'/>">Login page</a></span>
      </p>
    </bs:_loginPageDecoration>
  </jsp:attribute>
</bs:externalPage>
