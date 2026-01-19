<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="jetbrains.buildServer.controllers.resetPassword.ForgotPasswordController" %>
<%@ page import="jetbrains.buildServer.controllers.resetPassword.ResetPasswordController" %>
<%@ page import="jetbrains.buildServer.serverSide.crypt.RSACipher" %>
<%@ page import="static jetbrains.buildServer.controllers.resetPassword.ForgotPasswordController.DISABLED_ERROR_MSG" %>
<%@ page import="jetbrains.buildServer.serverSide.auth.resetPassword.ResetPasswordHandler" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<c:set var="title" value="Reset password"/>
<c:set var="link"><%=ResetPasswordHandler.URL_PATH%></c:set>
<c:set var="forgetLink"><%=ForgotPasswordController.URL_PATH%></c:set>
<bs:externalPage>
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/forms.css
      /css/maintenance-initialPages-common.css
      /css/initialPages.css
    </bs:linkCSS>
    <bs:ua/>
    <bs:linkScript>
      /js/crypt/rsa.js
      /js/crypt/jsbn.js
      /js/crypt/prng4.js
      /js/crypt/rng.js
      /js/bs/forms.js
      /js/bs/encrypt.js
      /js/bs/resetPassword/resetPassword.js
    </bs:linkScript>
    <style>
      #formNote {
        margin-top: 1em;
        font-size: 120%;
      }

      .resetPasswordPage {
        height: 100%;
      }

      .resetPasswordPage #loginPage form {
        width: 33em;
      }

      .resetPasswordPage #loginPage {
        width: 100%;
      }

      .resetPasswordPage #loginPage .passwordResetForm {
        margin-top: 2em;
      }

      .resetPasswordPage #loginPage td.passwordCell {
        width: 100%;
      }

      .resetPasswordPage #loginPage th {
        font-weight: normal;
        padding-right: 1em;
      }

      .resetPasswordPage #loginPage .loginButton {
        margin-top: 1.5em;
        width: 13em;
        margin-left: auto;
        margin-right: auto;
        display: block;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="resetPasswordPage">
    <bs:_loginPageDecoration id="loginPage" title="${title}">

        <c:choose>
           <c:when test="${!enabled}">
             <p id="formNote">
                 <c:set var="error" value="<%=DISABLED_ERROR_MSG%>"/>
                 <p>${error}</p>
             </p>
          </c:when>
           <c:when test="${token == null}">
             <p id="formNote">
               The reset password link has expired or is invalid. <br/>
               Try to <a href="<c:url value="${forgetLink}"/>">reset password</a> again.
             </p>
          </c:when>
          <c:otherwise>
            <%--@elvariable id="user" type="jetbrains.buildServer.users.SUser"--%>
            <div id="formNote">Please specify new password for the user <b><c:out value="${user.extendedName}"/></b></div>

              <form class="loginForm passwordResetForm" method="post" action="<c:url value="${link}"/>" onsubmit="BS.ResetPasswordForm.submit(); return false;">

                <table>
                  <tr class="formField">
                    <th><label for="password1">Password:<l:star/></label></th>
                    <td class="passwordCell"><input class="text" id="password1" type="password" name="password1">
                    </td>
                  </tr>
                  <tr class="formField">
                    <th><label for="retypedPassword">Confirm password:<l:star/></label></th>
                    <td class="passwordCell">
                      <span class="input-wrapper input-wrapper_retypedPassword"><input class="textField" id="retypedPassword" type="password" name="retypedPassword"
                                                                                       autocomplete="new-password"/></span>
                    </td>
                  </tr>
                  <tr>
                    <th class="loader-cell"><forms:saving className="progressRingSubmitBlock"/></th>
                    <td>
                      <noscript>
                        <div class="noJavaScriptEnabledMessage">
                          Please enable JavaScript in your browser to proceed with resetting the password.
                        </div>
                      </noscript>
                    </td>
                  </tr>
                </table>

                <input class="btn loginButton" type="submit" value="Submit"/>
                <span class="error" id="resetError" style="margin-left: 0;"></span>

                <input type="hidden" id="token" name="token" value="${token}"/>
                <input type="hidden" id="publicKey" name="publicKey" value="<c:out value='<%=RSACipher.getHexEncodedPublicKey()%>'/>"/>

              </form>
              <script type="text/javascript">
                $j(document).ready(function($) {
                  $j("#password1").focus();
                });
              </script>
          </c:otherwise>
        </c:choose>
      <p class="registerUser">
        <span><a href="<c:url value='/login.html'/>">Login page</a></span>
      </p>
    </bs:_loginPageDecoration>
    </div>
  </jsp:attribute>
</bs:externalPage>
