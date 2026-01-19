<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props"  %>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterEditContext"/>
<jsp:useBean id="cns" class="jetbrains.buildServer.controllers.parameters.types.TestFieldParameterConstants"/>
<jsp:useBean id="regexp" scope="request" type="java.lang.String"/>
<jsp:useBean id="validationMode" scope="request" type="java.lang.String"/>
<jsp:useBean id="newDialog" scope="request" type="java.lang.Boolean"/>

<c:choose>
  <c:when test="${newDialog}">
    <div id="allowedValueTooltip">
      <span id="showAllowedValue">
        <a class="btn allowedValues smallNote" id="showAllowedValuesBtn" href="#" role="button" showdiscardchangesmessage="false" style="border: 0">
          <bs:svgIcon name="chevron-down" />
          Show allowed value
        </a>
      </span>
      <span id="allowedValues">
        <a class="btn allowedValues smallNote" id="hideAllowedValuesBtn" href="#" role="button" showdiscardchangesmessage="false" style="border: 0">
          <bs:svgIcon name="chevron-up" />
          Hide allowed value
        </a>
        <label for="${cns.modeAny}">
          <props:radioButtonProperty id="${cns.modeAny}" name="${cns.mode}" value="${cns.modeAny}" checked="${validationMode eq cns.modeAny}"/>
          Any
        </label>
        <label for="${cns.modeNotEmpty}">
          <props:radioButtonProperty id="${cns.modeNotEmpty}" name="${cns.mode}" value="${cns.modeNotEmpty}" checked="${validationMode eq cns.modeNotEmpty}"/>
          Not Empty
        </label>
        <label for="${cns.modeRegex}">
          <props:radioButtonProperty id="${cns.modeRegex}" name="${cns.mode}" value="${cns.modeRegex}" checked="${validationMode eq cns.modeRegex}"/>
          Regex
        </label>
      </span>
    </div>
  </c:when>
  <c:otherwise>
    <tr class="addBorder">
      <th class="formHeader"><label for="textFieldMode">Allowed value:</label></th>
      <td>
        <props:selectProperty id="textFieldMode" name="${cns.mode}" className="longField" >
          <props:option value="${cns.modeAny}" selected="${validationMode eq cns.modeAny}">Any</props:option>
          <props:option value="${cns.modeNotEmpty}" selected="${validationMode eq cns.modeNotEmpty}">Not Empty</props:option>
          <props:option value="${cns.modeRegex}" selected="${validationMode eq cns.modeRegex}">Regex</props:option>
        </props:selectProperty>
      </td>
    </tr>
  </c:otherwise>
</c:choose>

<tr class="textFieldModeRegex">
  <th><label for="${cns.regexName}">Pattern:</label></th>
  <td>
    <props:textProperty name="${cns.regexName}" className="longField" value="${regexp}"/>
    <span class="smallNote">Specify a Java-style regular expression to validate field value</span>
    <span id="error_${cns.regexName}" class="error"></span>
  </td>
</tr>

<tr class="textFieldModeRegex">
  <th><label for="${cns.validationName}">Validation message:</label></th>
  <td>
    <props:textProperty name="${cns.validationName}" className="longField"/>
    <span class="smallNote">Specify text to show if regexp validation fails</span>
    <span id="error_${cns.validationName}" class="error"></span>
  </td>
</tr>

<script type="text/javascript">
  {
    const regexValue = "<bs:forJs>${cns.modeRegex}</bs:forJs>";
    const anyValue = "<bs:forJs>${cns.modeAny}</bs:forJs>";
    const showAllowedValueSpan = document.querySelector('#showAllowedValue');
    const allowedValuesSpan = document.querySelector('#allowedValues');
    function onTextFieldModeChange(inputValue) {
      const regexFields = document.querySelectorAll(".textFieldModeRegex");
      if (inputValue == regexValue) {
        regexFields.forEach(el => el.show());
      } else {
        regexFields.forEach(el => el.hide());
      }
    };

    function showAllowedValues(inputValue) {
      showAllowedValueSpan.hide();
      allowedValuesSpan.show();
      onTextFieldModeChange(inputValue);
    }

    function hideAllowedValues(inputValue) {
      allowedValuesSpan.hide();
      showAllowedValueSpan.show();
      onTextFieldModeChange(inputValue);
    }

    function onRadioInputModeChange(inputValue){
      if (inputValue != anyValue){
        showAllowedValues(inputValue);
      } else {
        hideAllowedValues(inputValue);
      }
    }

    function getCheckedRadio() {
      return document.querySelector(inputSelector + ':checked');
    }

    const textFieldInput = $("#textFieldMode");

    const inputSelector = 'input[name="prop:${cns.mode}"]';

    const checkedRadio = getCheckedRadio();
    if (textFieldInput){
      textFieldInput.change(() => onTextFieldModeChange(textFieldInput.val()));
      onTextFieldModeChange(textFieldInput.val());
    } else if (checkedRadio) {
      const radioInputs = document.querySelectorAll(inputSelector);
      radioInputs.forEach(input => {
        input.onclick = () => onTextFieldModeChange(input.value)
      });

      document.querySelector('#showAllowedValuesBtn').onclick = () => showAllowedValues(getCheckedRadio().value);
      document.querySelector('#hideAllowedValuesBtn').onclick = () => hideAllowedValues(getCheckedRadio().value);
      onRadioInputModeChange(checkedRadio.value)
    }
  }
</script>
