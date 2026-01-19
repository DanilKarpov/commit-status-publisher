<%@ include file="include-internal.jsp" %>
<c:set var="title" value="Set up Administrator Account"/>
<jsp:useBean id="loginDescription" beanName="loginDescription" scope="request" type="java.lang.String"/>
<jsp:useBean id="publicKey" beanName="publicKey" scope="request" type="java.lang.String"/>
<jsp:useBean id="defaultLoginConfigured" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="rootLoginAllowed" type="java.lang.Boolean" scope="request"/>
<bs:externalPage>
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/forms.css
      /css/maintenance-initialPages-common.css
      /css/initialPages.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/crypt/rsa.js
      /js/crypt/jsbn.js
      /js/crypt/prng4.js
      /js/crypt/rng.js
      /js/bs/forms.js
      /js/bs/encrypt.js
      /js/bs/setupAdmin.js
    </bs:linkScript>
    <bs:reactUi />
    <script>
      ReactUI.serviceWorkers.cleanServiceWorkerCaches();
      localStorage.clear();
      ReactUI.setGlobalTheme();
    </script>

    <script type="text/javascript">
      $j(document).ready(function($) {
        $("#input_teamcityUsername").focus();
      });
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:_loginPageDecoration id="setupAdminPage" title="${title}">
        <div id="errorMessage"></div>
        <c:if test="${fn:length(loginDescription) > 0}">
          <p id="loginDescription"><bs:out value="${loginDescription}"/></p>
        </c:if>

        <form action="<c:url value='/setupAdminSubmit.html'/>" onsubmit="return BS.SetupAdminForm.submitSetupAdmin(this);" method="post">

          <div>
            <label for="input_teamcityUsername">Username</label>
            <input class="text" id="input_teamcityUsername" type="text" name="username1" maxlength="191">
          </div>
          <div>
            <label for="password1">Password</label>
            <input class="text" id="password1" type="password" name="password1">
          </div>
          <div class="buttons">
            <th><forms:saving className="progressRingSubmitBlock"/></th>
            <td><input class="btn loginButton" type="submit" id="submitButton" value="Set as Administrator"/></td>
          </div>

          <input type="hidden" id="submitSetupAdmin" name="submitSetupAdmin" value=""/>
          <input type="hidden" id="publicKey" name="publicKey" value="${publicKey}"/>

        </form>

        <c:if test="${defaultLoginConfigured || rootLoginAllowed}">
          <p class="registerUser">
            <span class="greyNote">
              <c:if test="${defaultLoginConfigured}"><a href="<c:url value='/setupAdmin.html?create=1&init=1'/>">Create administrator account</a></c:if>
              <c:if test="${defaultLoginConfigured && rootLoginAllowed}">&nbsp;or&nbsp;</c:if>
              <c:if test="${rootLoginAllowed}"><a href="<c:url value='/login.html?super=1'/>">Login as Super user</a></c:if>
            </span>
          </p>
        </c:if>
    </bs:_loginPageDecoration>
  </jsp:attribute>
</bs:externalPage>
