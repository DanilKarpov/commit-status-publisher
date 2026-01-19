<%@ include file="/include-internal.jsp"
%><%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props"
%>

<prop:hiddenProperty name="secondFactorPolicy"/>

<input type="checkbox"
       name="allowSkipping2FACheckbox"
       id="allowSkipping2FACheckbox"
       onclick="setSecondFactorPolicy(this.checked)"
/>

<label width="100%" for="allowSkipping2FA">Skip two-factor authentication</label>

<script>
  function setSecondFactorPolicy(skip2FA) {
    if (skip2FA) {
      $j('#secondFactorPolicy').prop('value', 'NEVER_ASK');
    } else {
      $j('#secondFactorPolicy').prop('value', 'SKIP_IF_EXTERNAL_2FA');
    }
  }
  (function initCheckbox() {
    const value = $j('#secondFactorPolicy').val();
    const checkboxElement = document.getElementById('allowSkipping2FACheckbox');
    checkboxElement.checked = value === 'NEVER_ASK';
  })()
</script>

