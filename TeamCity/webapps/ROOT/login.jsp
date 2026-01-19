<%--no whitespace before page tag and <!DOCTYPE> --%><%@ include file="include-internal.jsp"
    %><jsp:useBean id="loginDescription" beanName="loginDescription" scope="request" type="java.lang.String"
    /><jsp:useBean id="canRegisterUsers" beanName="canRegisterUsers" scope="request" type="java.lang.Boolean"
    /><jsp:useBean id="guestLoginAllowed" beanName="guestLoginAllowed" scope="request" type="java.lang.Boolean"
    /><jsp:useBean id="publicKey" scope="request" type="java.lang.String"
    /><jsp:useBean id="unauthenticatedReason" scope="request" type="java.lang.String"
    /><jsp:useBean id="showNoAdminWarning" scope="request" type="java.lang.Boolean"
    /><jsp:useBean id="superUser" scope="request" type="java.lang.Boolean"
    /><jsp:useBean id="loginFormCollapsed" scope="request" type="java.lang.Boolean"
    /><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
    %><c:set var="title" value="Log in to TeamCity"
    /><c:if test="${superUser}"><c:set var="title" value="Log in as Super user"/></c:if><bs:externalPage>
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
      /js/aculo/effects.js
      /js/bs/forms.js
      /js/bs/encrypt.js
      /js/bs/login.js
    </bs:linkScript>
    <script>
      ReactUI.serviceWorkers.cleanServiceWorkerCaches();
      localStorage.clear();
      ReactUI.setGlobalTheme();
    </script>
    <script type="text/javascript">
      $j(document).ready(function($) {
        var loginForm = $('.loginForm');

        $("#username").focus();

        loginForm.attr('action', '<c:url value='/loginSubmit.html'/>');
        loginForm.submit(function() {
          return BS.LoginForm.submitLogin();
        });


        if (BS.Cookie.get("RecentLogin") !== null) {
          const errBlock = document.querySelector('#errorMessage');
          errBlock.textContent = "Clear the browser cookies or restart the browser to log in.";
          errBlock.style.display = "block";
          BS.Cookie.remove("RecentLogin");
        }

        if ($('#fading').length > 0) {
          BS.Highlight('fading');
        }

        const username = {
          name: 'Username',
          input: document.getElementById('username'),
          error: document.getElementById('username-error'),
          maxLength: 191
        };
        const password = {
          name: 'Password',
          input: document.getElementById('password'),
          error: document.getElementById('password-error'),
          maxLength: 128
        };
        const submit = document.querySelector('.loginButton');
        function validateInput({name, input, error, maxLength}) {
          if (input.value.length > maxLength) {
            input.classList.add('errorField');
            error.textContent = name + ' should be no longer than ' + maxLength + ' characters';
            return false
          } else {
            input.classList.remove('errorField');
            error.textContent = '';
            return true;
          }
        }
        function handleChange() {
          const usernameValid = validateInput(username);
          const passwordValid = validateInput(password);
          submit.disabled = !usernameValid || !passwordValid;
        }
        username.input.addEventListener('input', handleChange);
        password.input.addEventListener('input', handleChange);
      });
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:_loginPageDecoration id="loginPage" title="${title}">
      <c:if test="${!superUser && fn:length(loginDescription) > 0}">
        <div class="loginDescription"><bs:out value="${loginDescription}"/></div>
      </c:if>

      <jsp:include page="/loginIcons.html"/>

      <ext:includeExtensions placeId="LOGIN_PAGE_ICON"/>

      <ext:extensionsAvailable placeId="LOGIN_PAGE_ICON">
          <c:set value="${true}" var="iconsAvailable"/>
      </ext:extensionsAvailable>

      <div id="errorMessage" <c:if test="${not empty unauthenticatedReason}">style="display: block;"</c:if>><bs:out value="${unauthenticatedReason}" multilineOnly="${true}"/></div>

      <c:if test="${showNoAdminWarning}">
         <div class="attentionComment">
           <bs:buildStatusIcon type="red-sign" className="warningIcon"/>No System Administrator found.<bs:help file="HowTo-RetrieveAdministratorPassword"/> <br/>
           Log in <a href="<c:url value='/login.html?super=1'/>"> as a Super user</a> to create an administrator account.
         </div>
      </c:if>

      <c:if test="${superUser}">
        <input type="hidden" id="username" name="username" value="">
      </c:if>

      <div id="loginForm" <c:if test="${loginFormCollapsed}">hidden</c:if>>

        <form class="loginForm" method="post">
          <c:if test="${!superUser}">
            <div>
              <label for="username">Username</label>
              <input class="text" id="username" type="text" name="username">
              <span class="error" id="username-error"></span>
            </div>
          </c:if>

          <div>
            <label for="password"><c:choose><c:when test="${superUser}"
                  >Authentication token:<bs:help file="Super+User+Access"/></c:when
                  ><c:otherwise>Password</c:otherwise
            ></c:choose></label>
            <input class="text" id="password" type="password" name="password">
            <span class="error" id="password-error"></span>
          </div>


          <div class="remember-section">
          <div  class="remember-section__inner"><forms:checkbox className="checkbox" id="remember" name="remember" checked="${intprop:getBooleanOrTrue('teamcity.user.rememberMe.checkedByDefault')}"/>
            <label class="rememberMe" for="remember">Remember me</label></div>

            <span id="resetPasswordContainer"></span>
          </div>

          <noscript>
            <div class="noJavaScriptEnabledMessage">
              Please enable JavaScript in your browser to proceed with the login.
            </div>
          </noscript>


          <div class="buttons">
            <input class="btn loginButton" type="submit" name="submitLogin" value="Log in">
            <div class="loader-cell"><forms:saving className="progressRingSubmitBlock"/></div>
          </div>

          <input type="hidden" id="publicKey" name="publicKey" value="${publicKey}"/>
          <c:if test="${superUser}">
            <input type="hidden" name="super" value="1"/>
          </c:if>
        </form>

        <c:if test="${!superUser}">
          <c:if test="${canRegisterUsers}">
            <p class="registerUser">
              <span><a href="<c:url value='/registerUser.html?init=1'/>">Register a new user account</a></span>
            </p>
          </c:if>
        </c:if>
      </div>

      <c:if test="${loginFormCollapsed}">
        <div style="padding: 1em;" id="loginPasswordSwitch">
          <c:if test="${iconsAvailable}">or</c:if> <a href="#" style="color: gray; text-decoration: underline;" onclick="$j('#loginForm').removeAttr('hidden'); $j('#loginPasswordSwitch').attr('hidden', 'true');">continue with username/password</a>
        </div>
      </c:if>

      <c:if test="${!superUser}">
        <c:if test="${guestLoginAllowed}">
          <div>
            <a href="<c:url value='/guestLogin.html?guest=1'/>">Log in as guest</a>
          </div>
        </c:if>
        <jsp:include page="/loginExtensions.html"/>
      </c:if>
    </bs:_loginPageDecoration>
  </jsp:attribute>
</bs:externalPage>
